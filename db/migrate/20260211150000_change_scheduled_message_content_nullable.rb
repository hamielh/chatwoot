class ChangeScheduledMessageContentNullable < ActiveRecord::Migration[7.1]
  def change
    change_column_null :scheduled_messages, :content, true
  end
end
