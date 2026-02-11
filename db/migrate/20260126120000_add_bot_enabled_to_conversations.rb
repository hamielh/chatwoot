class AddBotEnabledToConversations < ActiveRecord::Migration[7.0]
  def change
    add_column :conversations, :bot_enabled, :boolean, default: true, null: false
  end
end
