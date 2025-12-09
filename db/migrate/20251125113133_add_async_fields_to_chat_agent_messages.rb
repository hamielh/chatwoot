class AddAsyncFieldsToChatAgentMessages < ActiveRecord::Migration[7.1]
  def change
    add_column :chat_agent_messages, :conversation_id, :string
    add_column :chat_agent_messages, :status, :string, default: 'completed'
    add_index :chat_agent_messages, :conversation_id
  end
end
