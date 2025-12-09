class AddWebhookParamsToChatAgents < ActiveRecord::Migration[7.1]
  def change
    add_column :chat_agents, :webhook_params, :jsonb, default: {}, null: false
  end
end
