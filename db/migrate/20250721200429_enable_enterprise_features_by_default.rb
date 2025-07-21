class EnableEnterpriseFeaturesByDefault < ActiveRecord::Migration[7.1]
  def up
    # Configurações globais aplicadas na criação do banco
    InstallationConfig.find_or_create_by(name: 'INSTALLATION_PRICING_PLAN') do |config|
      config.value = 'enterprise'
    end

    InstallationConfig.find_or_create_by(name: 'INSTALLATION_PRICING_PLAN_QUANTITY') do |config|
      config.value = 1000
    end

    # Se já existirem contas (caso de atualização), ativar features
    Account.find_each do |account|
      enable_premium_features_for_account(account)
    end
  end

  def down
    config = InstallationConfig.find_by(name: 'INSTALLATION_PRICING_PLAN')
    config&.update(value: 'community')

    config = InstallationConfig.find_by(name: 'INSTALLATION_PRICING_PLAN_QUANTITY')
    config&.update(value: 0)
  end

  private

  def enable_premium_features_for_account(account)
    premium_features = %w[
      disable_branding audit_logs response_bot sla
      captain_integration custom_roles help_center_embedding_search
      captain_integration_v2
    ]

    account.enable_features!(*premium_features)
    account.update(limits: { agents: 1000 })
  end
end
