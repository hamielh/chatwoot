class AddIconToSidebarApps < ActiveRecord::Migration[7.1]
  def change
    add_column :sidebar_apps, :icon, :string, default: 'i-lucide-app-window'
  end
end
