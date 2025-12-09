class ChangePhoneNumberNullInChannelWhatsappApi < ActiveRecord::Migration[7.1]
  def change
    change_column_null :channel_whatsapp_api, :phone_number, true
  end
end
