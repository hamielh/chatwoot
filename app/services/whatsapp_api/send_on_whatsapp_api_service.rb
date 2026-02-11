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

    base_url = InstallationConfig.find_by(name: 'QUEPASA_API_URL')&.value
    token = channel.provider_config['token']
    recipient = message.conversation.contact_inbox.source_id

    is_group = message.conversation.additional_attributes['is_group']
    chat_suffix = is_group ? '@g.us' : '@s.whatsapp.net'

    payload = {
      text: message.content.presence || ''
    }

    if message.attachments.any?
      attachment = message.attachments.first
      mime_type = attachment.file.content_type || 'application/octet-stream'

      # Baixar arquivo
      file_data = attachment.file.download

      # Converter áudios para OGG Opus (formato PTT com waveform)
      if mime_type.start_with?('audio/')
        file_data = convert_audio_to_opus(file_data)
        mime_type = 'audio/ogg; codecs=opus'
      end

      # Converter para base64
      base64_data = Base64.strict_encode64(file_data)

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

  def convert_audio_to_opus(input_data)
    require 'tempfile'

    input_file = Tempfile.new(['audio_input', '.mp3'])
    output_file = Tempfile.new(['audio_output', '.ogg'])

    begin
      # Escrever dados de entrada no arquivo temporário
      input_file.binmode
      input_file.write(input_data)
      input_file.close

      # Converter usando FFmpeg para OGG Opus (formato PTT do WhatsApp)
      # -ac 1: mono (1 canal)
      # -ar 16000: sample rate 16kHz (padrão WhatsApp)
      # -b:a 16k: bitrate 16kbps (qualidade PTT)
      # -c:a libopus: codec Opus
      command = "ffmpeg -i #{input_file.path} -ac 1 -ar 16000 -b:a 16k -c:a libopus #{output_file.path} -y 2>&1"

      Rails.logger.info "Converting audio to Opus: #{command}"
      output = `#{command}`

      unless $?.success?
        Rails.logger.error "FFmpeg conversion failed: #{output}"
        # Se falhar, retorna o arquivo original
        return input_data
      end

      # Ler arquivo convertido
      output_file.binmode
      converted_data = output_file.read

      Rails.logger.info "Audio converted successfully: #{input_data.size} bytes -> #{converted_data.size} bytes"

      converted_data
    ensure
      # Limpar arquivos temporários
      input_file.unlink if input_file
      output_file.unlink if output_file
    end
  end
end
