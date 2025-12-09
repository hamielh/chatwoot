class CreateChatAgents < ActiveRecord::Migration[7.1]
  def change
    create_table :chat_agents do |t|
      t.string :title, null: false
      t.string :icon, default: 'i-lucide-bot'
      t.string :webhook_url, null: false
      t.text :description
      t.text :allowed_roles, default: [], array: true
      t.integer :position, default: 0, null: false
      t.boolean :enabled, default: true
      t.references :account, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    add_index :chat_agents, [:account_id, :position]
  end
end
