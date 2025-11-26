class Api::V1::Accounts::ChatAgents::MessagesController < Api::V1::Accounts::BaseController
  before_action :check_chat_agents_feature_enabled
  before_action :fetch_chat_agent
  before_action :fetch_messages, only: [:index]

  def index; end

  def create
    # Save user message with processing status
    @user_message = @chat_agent.chat_agent_messages.create!(
      content: permitted_params[:message],
      role: 'user',
      status: 'processing',
      account_id: Current.account.id,
      user_id: Current.user.id
    )

    # Enqueue webhook job to process asynchronously
    ChatAgents::WebhookJob.perform_later(@user_message.id)

    # Return 202 Accepted with processing status
    @messages = [@user_message]
  rescue StandardError => e
    Rails.logger.error "ChatAgent message creation error: #{e.message}"
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def callback
    message_content = params[:message]

    Rails.logger.info "=== ChatAgent Callback START ==="
    Rails.logger.info "Account ID: #{Current.account.id}"
    Rails.logger.info "Chat Agent ID: #{@chat_agent.id}"
    Rails.logger.info "Message content: #{message_content}"

    unless message_content.present?
      return render json: { error: 'Missing message' }, status: :bad_request
    end

    # Create assistant response message
    @message = @chat_agent.chat_agent_messages.create!(
      content: message_content,
      role: 'assistant',
      status: 'completed',
      account_id: Current.account.id,
      user_id: Current.user.id
    )

    Rails.logger.info "Created assistant message ID: #{@message.id}"

    # Broadcast via WebSocket
    broadcast_message(@message)

    Rails.logger.info "Broadcast sent to channel: accounts:#{@message.account_id}:chat_agents"
    Rails.logger.info "=== ChatAgent Callback END ==="

    render json: { status: 'success', message_id: @message.id }, status: :ok
  rescue StandardError => e
    Rails.logger.error "ChatAgent callback error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
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

  def broadcast_message(message)
    data = {
      id: message.id,
      chat_agent_id: message.chat_agent_id,
      content: message.content,
      role: message.role,
      status: message.status,
      created_at: message.created_at.to_i,
      account_id: message.account_id
    }

    Rails.logger.info "Broadcasting chat_agent.message_received to account_#{message.account_id}"
    Rails.logger.info "Broadcast data: #{data.to_json}"

    ActionCableBroadcastJob.perform_later(
      ["account_#{message.account_id}"],
      'chat_agent.message_received',
      data
    )
  end

  def check_chat_agents_feature_enabled
    return if Current.account.feature_enabled?('chat_agents')

    render json: { error: 'Chat Agents feature is not enabled for this account' }, status: :forbidden
  end
end
