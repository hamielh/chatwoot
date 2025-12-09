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
      text: message.content.presence || ''
    }

    if message.attachments.any?
      attachment = message.attachments.first

      # Baixar arquivo e converter para base64
      file_data = attachment.file.download
      base64_data = Base64.strict_encode64(file_data)
      mime_type = attachment.file.content_type || 'application/octet-stream'

      # Converter áudios para formato PTT (áudio de voz com waveform)
      # Quepasa detecta PTT automaticamente com estes MIME types
      mime_type = 'audio/ogg; codecs=opus' if mime_type.start_with?('audio/')

      # Quepasa espera o formato: data:MIME_TYPE;base64,BASE64_DATA
      payload[:content] = "data:#{mime_type};base64,#{base64_data}"
    end

    if message.in_reply_to.present?
      replied_message = message.conversation.messages.find_by(id: message.in_reply_to)
      payload[:inreply] = replied_message.source_id if replied_message&.source_id.present?
    end

    Rails.logger.info "Quepasa payload: #{payload.inspect}"

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
end
