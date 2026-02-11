# frozen_string_literal: true

class Api::V1::Accounts::Channels::WhatsappApiController < Api::V1::Accounts::BaseController
  before_action :set_channel, only: [:scan, :info, :update_connection, :disconnect, :update_settings]

  def scan
    http_response = make_quepasa_request('/scan')

    if http_response&.success?
      send_data http_response.body, type: 'image/png', disposition: 'inline', status: :ok
    else
      error_msg = http_response&.body || 'Failed to generate QR code'
      Rails.logger.error("Quepasa /scan error: #{error_msg}")
      render json: { error: error_msg }, status: :unprocessable_entity
    end
  rescue StandardError => e
    Rails.logger.error("Quepasa /scan exception: #{e.message}")
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def info
    response = make_quepasa_request('/info')

    if response&.success?
      data = JSON.parse(response.body)
      Rails.logger.info("Quepasa /info response COMPLETO: #{data.inspect}")

      # Se não tem o objeto 'server', significa que ainda não conectou
      if data['server'].present?
        Rails.logger.info("Conexão encontrada: #{data['server'].inspect}")
        render json: data['server']
      else
        Rails.logger.warn("Conexão ainda não estabelecida. Resposta: #{data.inspect}")
        render json: { verified: false, connected: false }
      end
    else
      error_msg = response&.body || 'Failed to get connection info'
      Rails.logger.error("Quepasa /info error: #{error_msg}")
      render json: { error: error_msg }, status: :unprocessable_entity
    end
  rescue StandardError => e
    Rails.logger.error("Quepasa /info exception: #{e.message}")
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def update_connection
    connection_info = params[:connection_info]

    @channel.update!(
      provider_config: @channel.provider_config.merge(
        wid: connection_info[:wid],
        token: connection_info[:token],
        verified: connection_info[:verified],
        connected: true,
        connected_at: Time.current
      )
    )

    # Configurar webhook no Quepasa
    setup_webhook

    render json: { success: true }
  end

  def disconnect
    response = make_quepasa_request('/info', method: :delete)

    if response&.success?
      # Atualiza o canal para desconectado
      @channel.update!(
        provider_config: @channel.provider_config.merge(
          connected: false,
          verified: false,
          wid: nil,
          disconnected_at: Time.current
        )
      )

      render json: { success: true, message: 'WhatsApp desconectado com sucesso' }
    else
      error_msg = response&.body || 'Failed to disconnect'
      Rails.logger.error("Quepasa /info DELETE error: #{error_msg}")
      render json: { error: error_msg }, status: :unprocessable_entity
    end
  rescue StandardError => e
    Rails.logger.error("Quepasa disconnect exception: #{e.message}")
    render json: { error: e.message }, status: :unprocessable_entity
  end

  def update_settings
    ignore_groups = params[:ignore_groups]

    @channel.update!(
      provider_config: @channel.provider_config.merge(
        ignore_groups: ignore_groups
      )
    )

    render json: { success: true }
  rescue StandardError => e
    Rails.logger.error("Failed to update settings: #{e.message}")
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def set_channel
    @channel = Current.account.whatsapp_api_channels.find(params[:id])
  end

  def setup_webhook
    base_url = InstallationConfig.find_by(name: 'QUEPASA_API_URL')&.value
    token = @channel.provider_config['token']
    inbox_id = @channel.inbox.id

    # URL do webhook do Chatwoot
    webhook_url = "#{ENV.fetch('FRONTEND_URL', nil)}/api/v1/webhooks/whatsapp_api/#{inbox_id}"

    # Configurar webhook no Quepasa
    response = HTTParty.post(
      "#{base_url}/webhook",
      headers: {
        'Accept' => 'application/json',
        'Content-Type' => 'application/json',
        'X-QUEPASA-TOKEN' => token
      },
      body: {
        url: webhook_url,
        forwardinternal: true,
        trackid: "chatwoot-inbox-#{inbox_id}",
        extra: {
          clientId: 'chatwoot',
          inboxId: inbox_id
        }
      }.to_json,
      timeout: 10
    )

    if response.success?
      Rails.logger.info("Webhook configurado com sucesso: #{webhook_url}")
    else
      Rails.logger.error("Erro ao configurar webhook: #{response.body}")
    end
  rescue StandardError => e
    Rails.logger.error("Exceção ao configurar webhook: #{e.message}")
  end

  def make_quepasa_request(endpoint, method: :get)
    base_url = InstallationConfig.find_by(name: 'QUEPASA_API_URL')&.value

    # Gera um token único para este canal (20 caracteres aleatórios)
    token = @channel.provider_config['token']

    unless token
      token = SecureRandom.alphanumeric(20).downcase
      @channel.update!(provider_config: @channel.provider_config.merge(token: token))
      Rails.logger.info("Token gerado e salvo para o canal #{@channel.id}: #{token}")
    end

    user = InstallationConfig.find_by(name: 'QUEPASA_API_USER')&.value

    # A API do Quepasa usa query params, não path params
    url = "#{base_url}#{endpoint}?token=#{token}&user=#{CGI.escape(user)}"

    Rails.logger.info("Quepasa #{method.upcase} URL: #{url}")

    case method
    when :delete
      HTTParty.delete(url, timeout: 10)
    else
      HTTParty.get(url, timeout: 10)
    end
  end
end
