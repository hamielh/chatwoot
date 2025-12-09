class CreateChatAgentMessages < ActiveRecord::Migration[7.1]
  def change
    create_table :chat_agent_messages do |t|
      t.text :content, null: false
      t.string :role, null: false
      t.references :chat_agent, null: false, foreign_key: true
      t.references :account, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    add_index :chat_agent_messages, [:chat_agent_id, :created_at]
  end
end
