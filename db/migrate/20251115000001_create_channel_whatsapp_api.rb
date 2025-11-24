class CreateChannelWhatsappApi < ActiveRecord::Migration[7.1]
  def change
    create_table :channel_whatsapp_api do |t|
      t.string :phone_number, null: false
      t.jsonb :provider_config, default: {}
      t.integer :account_id, null: false
      t.timestamps
    end

    add_index :channel_whatsapp_api, :phone_number, unique: true
    add_index :channel_whatsapp_api, :account_id
  end
end
