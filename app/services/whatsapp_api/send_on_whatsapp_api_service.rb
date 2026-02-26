# frozen_string_literal: true

class WhatsappApi::SendOnWhatsappApiService < Base::SendOnChannelService
  MAX_SEND_RETRIES = 3
  RETRY_DELAYS = [2, 5, 10].freeze
  TRANSIENT_ERRORS = [
    SocketError,
    Errno::ECONNREFUSED,
    Errno::ECONNRESET,
    Errno::ETIMEDOUT,
    Errno::EHOSTUNREACH,
    Net::OpenTimeout,
    Net::ReadTimeout
  ].freeze

  private

  def channel_class
    Channel::WhatsappApi
  end

  def perform_reply
    send_message
  end

  def send_message
    payload = build_payload
    response = send_to_quepasa(payload)
    handle_response(response)
  rescue StandardError => e
    Rails.logger.error "WhatsappApi::SendOnWhatsappApiService error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    message.update!(status: :failed)
  end

  def build_payload
    payload = { text: message.content.presence || '' }
    attach_file(payload)
    attach_reply(payload)
    payload
  end

  def attach_file(payload)
    return unless message.attachments.any?

    attachment = message.attachments.first
    mime_type = attachment.file.content_type || 'application/octet-stream'

    attachment.file.blob.open do |tempfile|
      file_data = tempfile.read

      if mime_type.start_with?('audio/')
        file_data = convert_audio_to_opus(file_data)
        mime_type = 'audio/ogg; codecs=opus'
      end

      payload[:content] = "data:#{mime_type};base64,#{Base64.strict_encode64(file_data)}"
    end
  end

  def attach_reply(payload)
    return if message.in_reply_to.blank?

    replied_message = message.conversation.messages.find_by(id: message.in_reply_to)
    payload[:inreply] = replied_message.source_id if replied_message&.source_id.present?
  end

  def send_to_quepasa(payload)
    base_url = InstallationConfig.find_by(name: 'QUEPASA_API_URL')&.value
    token = channel.provider_config['token']
    recipient = message.conversation.contact_inbox.source_id
    chat_suffix = message.conversation.additional_attributes['is_group'] ? '@g.us' : '@s.whatsapp.net'

    Rails.logger.info "Quepasa payload: #{payload.inspect}"

    post_with_retry(
      "#{base_url}/v3/bot/#{token}/send",
      { 'Content-Type' => 'application/json', 'X-QUEPASA-CHATID' => "#{recipient}#{chat_suffix}" },
      payload.to_json
    )
  end

  def handle_response(response)
    unless response.success?
      Rails.logger.error "Quepasa send failed: #{response.code} - #{response.body}"
      message.update!(status: :failed)
      return
    end

    message_id = response.parsed_response.dig('message', 'id')
    if message_id
      message.update!(source_id: message_id, status: :delivered)
    else
      Rails.logger.error "Could not find message ID in Quepasa response: #{response.parsed_response.inspect}"
      message.update!(status: :failed)
    end
  end

  def post_with_retry(url, headers, body)
    attempt = 0
    begin
      attempt += 1
      HTTParty.post(url, headers: headers, body: body, timeout: 15)
    rescue *TRANSIENT_ERRORS => e
      if attempt <= MAX_SEND_RETRIES
        delay = RETRY_DELAYS[attempt - 1] || RETRY_DELAYS.last
        Rails.logger.warn(
          "Quepasa send attempt #{attempt}/#{MAX_SEND_RETRIES} failed " \
          "(#{e.class}: #{e.message}), retrying in #{delay}s..."
        )
        sleep(delay)
        retry
      end
      Rails.logger.error "Quepasa send failed after #{MAX_SEND_RETRIES} retries: #{e.message}"
      raise
    end
  end

  def convert_audio_to_opus(input_data)
    input_file = Tempfile.new(['audio_input', '.mp3'])
    output_file = Tempfile.new(['audio_output', '.ogg'])

    begin
      input_file.binmode
      input_file.write(input_data)
      input_file.close

      command = "ffmpeg -i #{input_file.path} -ac 1 -ar 16000 -b:a 16k -c:a libopus #{output_file.path} -y 2>&1"
      Rails.logger.info "Converting audio to Opus: #{command}"
      result = `#{command}`

      unless $CHILD_STATUS.success?
        Rails.logger.error "FFmpeg conversion failed: #{result}"
        return input_data
      end

      output_file.binmode
      output_file.read
    ensure
      input_file&.unlink
      output_file&.unlink
    end
  end
end
