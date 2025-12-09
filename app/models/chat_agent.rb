# == Schema Information
#
# Table name: chat_agents
#
#  id             :bigint           not null, primary key
#  allowed_roles  :text             default([]), is an Array
#  description    :text
#  enabled        :boolean          default(TRUE)
#  icon           :string           default("i-lucide-app-window")
#  position       :integer          default(0), not null
#  title          :string           not null
#  webhook_params :jsonb            not null
#  webhook_token  :string
#  webhook_url    :string           not null
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  account_id     :bigint           not null
#  user_id        :bigint           not null
#
# Indexes
#
#  index_chat_agents_on_account_id               (account_id)
#  index_chat_agents_on_account_id_and_position  (account_id,position)
#  index_chat_agents_on_user_id                  (user_id)
#  index_chat_agents_on_webhook_token            (webhook_token) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (user_id => users.id)
#
class ChatAgent < ApplicationRecord
  belongs_to :user
  belongs_to :account
  has_many :chat_agent_messages, dependent: :destroy

  validates :title, presence: true
  validates :webhook_url, presence: true, format: { with: URI::DEFAULT_PARSER.make_regexp(%w[http https]) }
  validates :position, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :icon, presence: true
  validate :validate_webhook_params

  scope :ordered, -> { order(position: :asc, created_at: :asc) }
  scope :enabled, -> { where(enabled: true) }
  scope :for_role, ->(role) { where('allowed_roles = ARRAY[]::text[] OR ? = ANY(allowed_roles)', role) }

  private

  def validate_webhook_params
    return if webhook_params.blank?

    unless webhook_params.is_a?(Hash)
      errors.add(:webhook_params, 'must be a valid JSON object')
      return
    end

    webhook_params.each do |key, value|
      errors.add(:webhook_params, "key '#{key}' cannot be blank") if key.blank?
      errors.add(:webhook_params, "value for '#{key}' must be a string") unless value.is_a?(String)
    end
  end
end
