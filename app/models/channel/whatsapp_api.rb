# frozen_string_literal: true

# == Schema Information
#
# Table name: channel_whatsapp_api
#
#  id              :bigint           not null, primary key
#  phone_number    :string
#  provider_config :jsonb
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  account_id      :integer          not null
#
# Indexes
#
#  index_channel_whatsapp_api_on_account_id    (account_id)
#  index_channel_whatsapp_api_on_phone_number  (phone_number) UNIQUE
#
class Channel::WhatsappApi < ApplicationRecord
  include Channelable

  self.table_name = 'channel_whatsapp_api'
  EDITABLE_ATTRS = [:phone_number, { provider_config: {} }].freeze

  validates :phone_number, uniqueness: true, allow_blank: true

  before_validation :normalize_phone_number
  before_destroy :disconnect_from_quepasa

  def name
    'WhatsApp API'
  end

  def messaging_window_enabled?
    true
  end

  def has_24_hour_messaging_window?
    true
  end

  private

  def normalize_phone_number
    self.phone_number = nil if phone_number.blank?
  end

  def disconnect_from_quepasa
    return unless provider_config['token'].present?

    base_url = InstallationConfig.find_by(name: 'QUEPASA_API_URL')&.value
    return unless base_url.present?

    token = provider_config['token']
    user = InstallationConfig.find_by(name: 'QUEPASA_API_USER')&.value

    url = "#{base_url}/info?token=#{token}&user=#{CGI.escape(user)}"

    Rails.logger.info("Desconectando WhatsApp do Quepasa: #{token}")
    HTTParty.delete(url, timeout: 10)
  rescue StandardError => e
    Rails.logger.error("Erro ao desconectar do Quepasa: #{e.message}")
    # Não impede a exclusão do canal se falhar
    true
  end
end
