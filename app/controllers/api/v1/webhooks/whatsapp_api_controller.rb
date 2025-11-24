# frozen_string_literal: true

class Api::V1::Webhooks::WhatsappApiController < ActionController::API
  def create
    # Encontrar inbox pelo ID na URL
    inbox = ::Inbox.find(params[:inbox_id])
    channel = inbox.channel

    # Validar que é Channel::WhatsappApi
    return head :not_found unless channel.is_a?(Channel::WhatsappApi)

    # Validar que conta está ativa
    return head :unprocessable_entity unless channel.account.active?

    # Processar assincronamente
    Webhooks::WhatsappApiEventsJob.perform_later(
      inbox_id: inbox.id,
      params: params.to_unsafe_hash
    )

    head :ok
  rescue ActiveRecord::RecordNotFound
    head :not_found
  end
end
