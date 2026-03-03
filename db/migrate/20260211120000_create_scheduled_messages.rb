class CreateScheduledMessages < ActiveRecord::Migration[7.1]
  def change
    create_table :scheduled_messages do |t|
      t.references :account, null: false, index: true
      t.references :conversation, null: false, index: true
      t.text :content, null: false
      t.datetime :scheduled_at, null: false
      t.integer :status, default: 0, null: false
      t.references :created_by, polymorphic: true, null: false
      t.timestamps
    end
    add_index :scheduled_messages, %i[scheduled_at status]
  end
end
