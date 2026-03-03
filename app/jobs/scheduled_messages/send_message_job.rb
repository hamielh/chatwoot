class ScheduledMessages::SendMessageJob < ApplicationJob
  queue_as :default

  def perform(scheduled_message)
    return unless scheduled_message.pending?

    params = build_params(scheduled_message)
    Messages::MessageBuilder.new(scheduled_message.created_by, scheduled_message.conversation, params).perform
    scheduled_message.sent!
  rescue StandardError => e
    scheduled_message.failed!
    Rails.logger.error "ScheduledMessage##{scheduled_message.id} failed: #{e.message}"
  end

  private

  def build_params(scheduled_message)
    params = {
      content: scheduled_message.content,
      message_type: 'outgoing',
      private: scheduled_message.private
    }
    return params unless scheduled_message.files.attached?

    params[:attachments] = scheduled_message.files.map do |file|
      blob = file.blob
      tempfile = Tempfile.new([blob.filename.base, ".#{blob.filename.extension}"])
      tempfile.binmode
      blob.download { |chunk| tempfile.write(chunk) }
      tempfile.rewind
      ActionDispatch::Http::UploadedFile.new(
        tempfile: tempfile,
        filename: blob.filename.to_s,
        type: blob.content_type
      )
    end
    params
  end
end
