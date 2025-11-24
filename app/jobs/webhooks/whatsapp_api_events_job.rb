# frozen_string_literal: true

class Webhooks::WhatsappApiEventsJob < ApplicationJob
  queue_as :default

  def perform(inbox_id:, params:)
    Rails.logger.info("WhatsappApiEventsJob - Starting - Inbox ID: #{inbox_id}")
    Rails.logger.info("WhatsappApiEventsJob - Params: #{params.inspect}")

    inbox = ::Inbox.find_by(id: inbox_id)

    if inbox.blank?
      Rails.logger.error("WhatsappApiEventsJob - Inbox not found: #{inbox_id}")
      return
    end

    unless inbox.account.active?
      Rails.logger.error("WhatsappApiEventsJob - Account not active: #{inbox.account_id}")
      return
    end

    Rails.logger.info("WhatsappApiEventsJob - Processing message for inbox #{inbox.id}")

    # Processar mensagem
    WhatsappApi::IncomingMessageService.new(
      inbox: inbox,
      params: params
    ).perform

    Rails.logger.info('WhatsappApiEventsJob - Message processed successfully')
  rescue StandardError => e
    Rails.logger.error("WhatsappApiEventsJob - Error: #{e.message}")
    Rails.logger.error(e.backtrace.join("\n"))
    raise
  end
end
