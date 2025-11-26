class AddAsyncFieldsToChatAgents < ActiveRecord::Migration[7.1]
  def change
    add_column :chat_agents, :webhook_token, :string
    add_index :chat_agents, :webhook_token, unique: true

    # Generate tokens for existing agents
    reversible do |dir|
      dir.up do
        execute <<-SQL
          UPDATE chat_agents
          SET webhook_token = encode(gen_random_bytes(32), 'hex')
          WHERE webhook_token IS NULL
        SQL
      end
    end
  end
end
