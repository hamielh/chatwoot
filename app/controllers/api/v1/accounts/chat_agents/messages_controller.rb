class Api::V1::Accounts::ChatAgents::MessagesController < Api::V1::Accounts::BaseController
  before_action :fetch_chat_agent
  before_action :fetch_messages, only: [:index]

  def index; end

  def create
    # Save user message
    @user_message = @chat_agent.chat_agent_messages.create!(
      content: permitted_params[:message],
      role: 'user',
      account_id: Current.account.id,
      user_id: Current.user.id
    )

    # Call webhook
    response = call_webhook(@chat_agent.webhook_url, permitted_params[:message])

    # Save assistant response
    @assistant_message = @chat_agent.chat_agent_messages.create!(
      content: response[:content],
      role: 'assistant',
      account_id: Current.account.id,
      user_id: Current.user.id
    )

    @messages = [@user_message, @assistant_message]
  rescue StandardError => e
    Rails.logger.error "ChatAgent webhook error: #{e.message}"
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def destroy_all
    @chat_agent.chat_agent_messages.destroy_all
    head :no_content
  end

  private

  def fetch_chat_agent
    @chat_agent = Current.account.chat_agents.find(params[:chat_agent_id])
  end

  def fetch_messages
    @messages = @chat_agent.chat_agent_messages.ordered
  end

  def permitted_params
    params.permit(:message, :chat_agent_id)
  end

  def call_webhook(webhook_url, message)
    payload = {
      message: message,
      user_id: Current.user.id,
      account_id: Current.account.id,
      agent_id: @chat_agent.id
    }

    response = HTTParty.post(
      webhook_url,
      body: payload.to_json,
      headers: { 'Content-Type' => 'application/json' },
      timeout: 30
    )

    if response.success?
      { content: response.parsed_response['message'] || response.body }
    else
      raise "Webhook failed with status #{response.code}"
    end
  end
end
