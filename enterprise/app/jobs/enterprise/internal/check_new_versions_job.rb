module Enterprise::Internal::CheckNewVersionsJob
  def perform
    # ===== BYPASS ENTERPRISE =====
    Rails.logger.info "🚫 Enterprise version check bypassed - maintaining enterprise config"

    # Executar apenas a parte de versão (inofensiva)
    super

    # PULAR as partes problemáticas:
    # - update_plan_info (não executar)
    # - reconcile_premium_config_and_features (não executar)

    # Em vez disso, garantir que configurações enterprise permaneçam
    maintain_enterprise_config
    # ==========================
  end

  private

  def maintain_enterprise_config
    return unless ChatwootApp.enterprise?

    # Forçar configurações enterprise (sem lock)
    config_plan = InstallationConfig.find_or_create_by(name: 'INSTALLATION_PRICING_PLAN')
    config_plan.update(value: 'enterprise', locked: false)

    config_quantity = InstallationConfig.find_or_create_by(name: 'INSTALLATION_PRICING_PLAN_QUANTITY')
    config_quantity.update(value: 1000, locked: false)

    Rails.logger.info "✅ Enterprise configuration maintained"
  rescue => e
    Rails.logger.error "Failed to maintain enterprise config: #{e.message}"
  end

  # Métodos originais DESABILITADOS:
  def update_plan_info
    Rails.logger.info "🚫 update_plan_info bypassed"
    # Código original comentado/removido
  end

  def update_installation_config(key:, value:)
    Rails.logger.info "🚫 update_installation_config bypassed for #{key}"
    # Código original comentado/removido
  end

  def reconcile_premium_config_and_features
    Rails.logger.info "🚫 reconcile_premium_config_and_features bypassed"
    # Código original comentado/removido
  end
end
