# frozen_string_literal: true

class WhatsappApi::SendOnWhatsappApiService < Base::SendOnChannelService
  private

  def channel_class
    Channel::WhatsappApi
  end

  def perform_reply
    send_message
  end

  def send_message
    message.update!(status: :delivered)

    base_url = ENV.fetch('QUEPASA_API_URL', 'https://pixel-quepasa.f7unst.easypanel.host')
    token = channel.provider_config['token']
    recipient = message.conversation.contact_inbox.source_id

    is_group = message.conversation.additional_attributes['is_group']
    chat_suffix = is_group ? '@g.us' : '@s.whatsapp.net'

    payload = {
      text: message.content
    }

    if message.attachments.any?
      attachment = message.attachments.first
      payload[:attachment] = rails_blob_url(attachment.file)
    end

    if message.in_reply_to.present?
      replied_message = message.conversation.messages.find_by(id: message.in_reply_to)
      payload[:inreply] = replied_message.source_id if replied_message&.source_id.present?
    end

    response = HTTParty.post(
      "#{base_url}/v3/bot/#{token}/send",
      headers: {
        'Content-Type' => 'application/json',
        'X-QUEPASA-CHATID' => "#{recipient}#{chat_suffix}"
      },
      body: payload.to_json,
      timeout: 15
    )

    if response.success?
      parsed = response.parsed_response
      message_id = parsed.dig('message', 'id')

      if message_id
        message.update!(source_id: message_id)
      else
        Rails.logger.error "Could not find message ID in Quepasa response: #{parsed.inspect}"
        message.update!(status: :failed)
      end
    else
      Rails.logger.error "Quepasa send failed: #{response.code} - #{response.body}"
      message.update!(status: :failed)
    end
  rescue StandardError => e
    Rails.logger.error "WhatsappApi::SendOnWhatsappApiService error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    message.update!(status: :failed)
  end

  def rails_blob_url(file)
    return nil unless file.attached?

    Rails.application.routes.url_helpers.rails_blob_url(file, host: ENV.fetch('FRONTEND_URL', 'http://localhost:3000'))
  end
end
