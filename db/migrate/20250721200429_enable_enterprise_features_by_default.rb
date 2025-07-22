# db/migrate/20250721200429_enable_enterprise_features_by_default.rb
class EnableEnterpriseFeaturesByDefault < ActiveRecord::Migration[7.1]
  def up
    # Configurar plano enterprise
    InstallationConfig.find_or_create_by(name: 'INSTALLATION_PRICING_PLAN') do |config|
      config.value = 'enterprise'
    end

    # Configurar quantidade alta de licenças
    InstallationConfig.find_or_create_by(name: 'INSTALLATION_PRICING_PLAN_QUANTITY') do |config|
      config.value = 1000
    end

    # ===== CORREÇÃO PROBLEMA 1: ONBOARDING =====
    # Forçar onboarding mesmo com configs enterprise
    begin
      Redis::Alfred.set(Redis::Alfred::CHATWOOT_INSTALLATION_ONBOARDING, true)
      Rails.logger.info '✅ Onboarding flag set successfully'
    rescue StandardError => e
      Rails.logger.warn "⚠️ Could not set onboarding flag: #{e.message}"
    end
    # ==========================================

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

    # Limpar flag de onboarding
    begin
      Redis::Alfred.delete(Redis::Alfred::CHATWOOT_INSTALLATION_ONBOARDING)
    rescue StandardError => e
      Rails.logger.warn "Could not clear onboarding flag: #{e.message}"
    end
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
  rescue StandardError => e
    Rails.logger.error "Failed to enable features for account #{account.id}: #{e.message}"
  end
end
