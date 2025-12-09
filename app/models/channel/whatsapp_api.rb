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

  def name
    'WhatsApp API'
  end

  def messaging_window_enabled?
    true
  end

  def has_24_hour_messaging_window?
    true
  end
end
