# == Schema Information
#
# Table name: chat_agent_messages
#
#  id            :bigint           not null, primary key
#  content       :text             not null
#  role          :string           not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  account_id    :bigint           not null
#  chat_agent_id :bigint           not null
#  user_id       :bigint           not null
#
# Indexes
#
#  index_chat_agent_messages_on_account_id                    (account_id)
#  index_chat_agent_messages_on_chat_agent_id                 (chat_agent_id)
#  index_chat_agent_messages_on_chat_agent_id_and_created_at  (chat_agent_id,created_at)
#  index_chat_agent_messages_on_user_id                       (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (account_id => accounts.id)
#  fk_rails_...  (chat_agent_id => chat_agents.id)
#  fk_rails_...  (user_id => users.id)
#
class ChatAgentMessage < ApplicationRecord
  ROLES = %w[user assistant].freeze

  belongs_to :chat_agent
  belongs_to :account
  belongs_to :user

  validates :content, presence: true
  validates :role, presence: true, inclusion: { in: ROLES }

  scope :ordered, -> { order(created_at: :asc) }
  scope :for_agent, ->(agent_id) { where(chat_agent_id: agent_id) }
end
