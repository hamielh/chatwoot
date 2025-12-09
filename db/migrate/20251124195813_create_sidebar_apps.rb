class CreateSidebarApps < ActiveRecord::Migration[7.1]
  def change
    create_table :sidebar_apps do |t|
      t.string :title, null: false
      t.string :url, null: false
      t.bigint :account_id, null: false
      t.bigint :user_id
      t.text :allowed_roles, array: true, default: []
      t.string :display_location, default: 'apps_menu', null: false
      t.integer :position, default: 0, null: false

      t.timestamps
    end

    add_index :sidebar_apps, :account_id
    add_index :sidebar_apps, :user_id
  end
end
