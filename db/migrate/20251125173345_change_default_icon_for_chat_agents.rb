class ChangeDefaultIconForChatAgents < ActiveRecord::Migration[7.1]
  def change
    change_column_default :chat_agents, :icon, from: 'i-lucide-bot', to: 'i-lucide-app-window'

    # Update existing records that have the old default icon
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE chat_agents
          SET icon = 'i-lucide-app-window'
          WHERE icon = 'i-lucide-bot'
        SQL
      end

      dir.down do
        execute <<-SQL
          UPDATE chat_agents
          SET icon = 'i-lucide-bot'
          WHERE icon = 'i-lucide-app-window'
        SQL
      end
    end
  end
end
