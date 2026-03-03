class AddPrivateToScheduledMessages < ActiveRecord::Migration[7.1]
  def change
    add_column :scheduled_messages, :private, :boolean, default: false, null: false
  end
end
