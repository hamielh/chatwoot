class ChatAgents::WebhookJob < ApplicationJob
  queue_as :default

  def perform(message_id)
    message = ChatAgentMessage.find(message_id)
    chat_agent = message.chat_agent

    Rails.logger.info "ChatAgentWebhookJob: Processing message #{message_id} for agent #{chat_agent.id}"

    # Prepare payload - SIMPLES!
    payload = {
      message: message.content,
      user_id: message.user_id,
      account_id: message.account_id,
      agent_id: chat_agent.id
    }

    Rails.logger.info "ChatAgentWebhookJob: Calling webhook #{chat_agent.webhook_url}"

    # Call webhook
    response = HTTParty.post(
      chat_agent.webhook_url,
      body: payload.to_json,
      headers: { 'Content-Type' => 'application/json' },
      timeout: 120
    )

    Rails.logger.info "ChatAgentWebhookJob: Webhook response status=#{response.code} body=#{response.body}"

    # If webhook responds immediately (sync mode), save the response
    if response.success? && response.parsed_response.is_a?(Hash) && response.parsed_response['message'].present?
      Rails.logger.info "ChatAgentWebhookJob: Creating assistant message with response"
      handle_sync_response(message, response.parsed_response['message'])
    else
      Rails.logger.info "ChatAgentWebhookJob: No sync response, waiting for callback"
    end

    # Mark user message as completed (mesmo que não tenha resposta síncrona)
    message.update!(status: 'completed')
    broadcast_message(message)
  rescue StandardError => e
    Rails.logger.error "ChatAgent webhook job error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    mark_as_error(message, e.message)
  end

  private

  def handle_sync_response(user_message, response_content)
    # Create assistant message with the response
    assistant_message = user_message.chat_agent.chat_agent_messages.create!(
      content: response_content,
      role: 'assistant',
      status: 'completed',
      account_id: user_message.account_id,
      user_id: user_message.user_id
    )

    # Broadcast assistant message
    broadcast_message(assistant_message)
  end

  def mark_as_error(message, error_message)
    message.update!(status: 'error')
    broadcast_message(message)
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

    Rails.logger.info "ChatAgentWebhookJob: Broadcasting chat_agent.message_received to account_#{message.account_id}"
    Rails.logger.info "ChatAgentWebhookJob: Broadcast data: #{data.to_json}"

    ActionCableBroadcastJob.perform_later(
      ["account_#{message.account_id}"],
      'chat_agent.message_received',
      data
    )
  end
end
