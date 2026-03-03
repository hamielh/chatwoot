class AddBotEnabledDefaultToInboxes < ActiveRecord::Migration[7.1]
  def change
    add_column :inboxes, :bot_enabled_default, :boolean, default: true, null: false
  end
end
