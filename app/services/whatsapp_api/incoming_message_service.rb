# frozen_string_literal: true

class WhatsappApi::IncomingMessageService
  pattr_initialize [:inbox!, :params!]

  def perform
    return if message_params.blank?
    return if group_message? && ignore_groups?

    existing_message = Message.find_by(source_id: message_params['id'] || message_params[:id])
    return if existing_message

    set_contact
    set_conversation
    create_message
    process_attachments if attachment?
    @message.save!
    set_attachment_metadata if attachment?
  end

  private

  def message_params
    # Quepasa envia os dados direto no root, não dentro de 'message'
    @message_params ||= params
  end

  def phone_number
    phone = if group_message?
              group_id = message_params.dig('chat', 'id') || message_params.dig(:chat, :id)
              group_id&.split('@')&.first
            else
              message_params.dig('chat', 'phone') || message_params.dig(:chat, :phone)
            end

    @phone_number ||= phone&.gsub(/[+@]/, '')
  end

  def contact_name
    name = message_params.dig('chat', 'title') || message_params.dig(:chat, :title)
    (name.presence || phone_number)
  end

  def participant_name
    return nil unless group_message?

    message_params.dig('participant', 'title') || message_params.dig(:participant, :title)
  end

  def set_contact
    contact_attrs = {
      name: contact_name,
      additional_attributes: {
        social_whatsapp_phone_number: phone_number
      }
    }

    contact_attrs[:phone_number] = "+#{phone_number}" unless group_message?

    contact_inbox = ::ContactInboxWithContactBuilder.new(
      source_id: phone_number,
      inbox: inbox,
      contact_attributes: contact_attrs
    ).perform

    @contact_inbox = contact_inbox
    @contact = contact_inbox.contact

    update_contact_avatar
  end

  def update_contact_avatar
    return if @contact.avatar.attached?

    phone = phone_number.gsub(/\D/, '')

    # Remove o 9º dígito se for celular brasileiro (formato: 55 + DDD + 9 + 8 dígitos)
    phone = phone[0..3] + phone[5..] if phone.start_with?('55') && phone.length == 13 && phone[4] == '9'

    base_url = ENV.fetch('QUEPASA_API_URL', 'https://pixel-quepasa.f7unst.easypanel.host')
    token = inbox.channel.provider_config['token']

    response = HTTParty.get(
      "#{base_url}/picinfo/#{phone}",
      headers: {
        'X-QUEPASA-TOKEN' => token
      },
      timeout: 10
    )

    if response.success? && response['success']
      avatar_url = response.dig('info', 'url')

      if avatar_url.present?
        avatar_response = HTTParty.get(avatar_url, timeout: 15)

        if avatar_response.success? && avatar_response.body.present?
          tempfile = Tempfile.new(['avatar', '.jpg'])
          tempfile.binmode
          tempfile.write(avatar_response.body)
          tempfile.rewind

          @contact.avatar.attach(
            io: tempfile,
            filename: "avatar_#{@contact.id}.jpg",
            content_type: 'image/jpeg'
          )

          tempfile.close
          tempfile.unlink
        end
      end
    end
  rescue StandardError => e
    Rails.logger.error "Failed to download avatar: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
  end

  def set_conversation
    # Get chat_id from message params to find the correct conversation
    chat_id = message_params.dig('chat', 'id') || message_params.dig(:chat, :id)

    # Try to find existing conversation by chat_id first (more accurate)
    if chat_id.present?
      @conversation = @contact_inbox.conversations
                                    .where.not(status: :resolved)
                                    .find_by("additional_attributes->>'chat_id' = ?", chat_id)
    end

    # Fallback to last conversation if not found by chat_id
    @conversation ||= @contact_inbox.conversations
                                    .where.not(status: :resolved)
                                    .last

    # Update chat_id if conversation exists but doesn't have one
    if @conversation && chat_id.present?
      existing_chat_id = @conversation.additional_attributes['chat_id']
      if existing_chat_id.blank?
        additional_attrs = @conversation.additional_attributes.dup
        additional_attrs['chat_id'] = chat_id
        @conversation.update!(additional_attributes: additional_attrs)
        @conversation.reload
      end
    end

    return if @conversation

    attrs = {
      account_id: inbox.account_id,
      inbox_id: inbox.id,
      contact_id: @contact.id,
      contact_inbox_id: @contact_inbox.id,
      additional_attributes: {
        chat_id: message_params['from'] || message_params[:from]
      }
    }

    if group_message?
      group_name = message_params.dig('chat', 'title') || message_params.dig(:chat, :title)
      attrs[:additional_attributes][:chat_id] = chat_id
      attrs[:additional_attributes][:is_group] = true
      attrs[:additional_attributes][:group_name] = group_name
    end

    @conversation = ::Conversation.create!(attrs)
  end

  def create_message
    message_attrs = {
      content: message_content,
      account_id: inbox.account_id,
      inbox_id: inbox.id,
      message_type: message_type,
      sender: message_sender,
      source_id: message_params['id'] || message_params[:id],
      status: :sent
    }

    if replied_message_id.present?
      replied_message = @conversation.messages.find_by(source_id: replied_message_id)
      message_attrs[:in_reply_to] = replied_message.id if replied_message
    end

    @message = @conversation.messages.build(message_attrs)
  end

  def replied_message_id
    message_params['inreply'] || message_params[:inreply]
  end

  def message_content
    content = message_params['text'] || message_params[:text] || ''

    content = "reagiu com #{content}" if is_reaction?

    if group_message? && participant_name.present?
      "*#{participant_name}:*\n#{content}"
    else
      content
    end
  end

  def is_reaction?
    message_params['inreaction'] == true || message_params[:inreaction] == true
  end

  def message_type
    from_me? ? :outgoing : :incoming
  end

  def message_sender
    from_me? ? nil : @contact
  end

  def from_me?
    message_params['fromme'] == true || message_params[:fromme] == true ||
      message_params['fromMe'] == true || message_params[:fromMe] == true
  end

  def group_message?
    chat_id = message_params.dig('chat', 'id') || message_params.dig(:chat, :id) ||
              message_params['from'] || message_params[:from]
    chat_id&.end_with?('@g.us')
  end

  def ignore_groups?
    inbox.channel.reload.provider_config['ignore_groups'] == true
  end

  def attachment?
    message_params['attachment'].present? || message_params[:attachment].present?
  end

  def process_attachments
    attachment_data = message_params['attachment'] || message_params[:attachment]
    return unless attachment_data

    if location_attachment?
      process_location_attachment
      return
    end

    download_url = attachment_data['url'] || attachment_data[:url]

    unless download_url
      message_id = message_params['id'] || message_params[:id]
      base_url = ENV.fetch('QUEPASA_API_URL', 'https://pixel-quepasa.f7unst.easypanel.host')
      download_url = "#{base_url}/download/#{message_id}"
    end

    token = inbox.channel.provider_config['token']

    response = HTTParty.get(
      download_url,
      headers: {
        'X-QUEPASA-TOKEN' => token
      },
      timeout: 30
    )

    if response.success? && response.body.present?
      mime = attachment_data['mime'] || attachment_data[:mime]
      extension = detect_extension(mime)
      filename = attachment_data['filename'] || attachment_data[:filename] || "attachment#{extension}"

      tempfile = Tempfile.new(['attachment', extension])
      tempfile.binmode
      tempfile.write(response.body)
      tempfile.rewind

      @message.attachments.new(
        account_id: @message.account_id,
        file_type: detect_file_type(message_params['type'] || message_params[:type]),
        file: {
          io: tempfile,
          filename: filename,
          content_type: mime
        }
      )
    else
      Rails.logger.error("Failed to download attachment: #{response.code}")
    end
  rescue StandardError => e
    Rails.logger.error("Error processing attachment: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
  end

  def set_attachment_metadata
    attachment_data = message_params['attachment'] || message_params[:attachment]
    return unless attachment_data

    duration = attachment_data['seconds'] || attachment_data[:seconds]
    return unless duration

    @message.attachments.reload.each do |attachment|
      next unless attachment.file.attached?

      blob = attachment.file.blob
      blob.metadata['duration'] = duration.to_f
      blob.save!
    end
  rescue StandardError => e
    Rails.logger.error("Error setting attachment metadata: #{e.message}")
  end

  def location_attachment?
    type = message_params['type'] || message_params[:type]
    type == 'location'
  end

  def process_location_attachment
    attachment_data = message_params['attachment'] || message_params[:attachment]

    latitude = attachment_data['latitude'] || attachment_data[:latitude]
    longitude = attachment_data['longitude'] || attachment_data[:longitude]
    map_url = attachment_data['url'] || attachment_data[:url]

    @message.attachments.new(
      account_id: @message.account_id,
      file_type: :location,
      coordinates_lat: latitude,
      coordinates_long: longitude,
      external_url: map_url
    )
  rescue StandardError => e
    Rails.logger.error("Error processing location: #{e.message}")
  end

  def detect_file_type(type)
    case type
    when 'image' then :image
    when 'audio', 'voice' then :audio
    when 'video' then :video
    when 'document' then :file
    else :file
    end
  end

  def detect_extension(mime)
    case mime
    when 'image/jpeg' then '.jpg'
    when 'image/png' then '.png'
    when 'image/gif' then '.gif'
    when 'image/webp' then '.webp'
    when 'audio/ogg; codecs=opus', 'audio/ogg' then '.ogg'
    when 'audio/mpeg' then '.mp3'
    when 'audio/mp4' then '.m4a'
    when 'video/mp4' then '.mp4'
    when 'video/3gpp' then '.3gp'
    when 'application/pdf' then '.pdf'
    when 'application/vnd.openxmlformats-officedocument.wordprocessingml.document' then '.docx'
    when 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet' then '.xlsx'
    else '.bin'
    end
  end
end
