class Internal::ReconcilePlanConfigService
  def perform
    # ===== SERVIÇO NEUTRALIZADO =====
    Rails.logger.info "🚫 ReconcilePlanConfigService bypassed - enterprise mode active"

    remove_premium_config_reset_warning

    # PULAR todas as verificações destrutivas se enterprise estiver ativo
    if ChatwootApp.enterprise? && enterprise_mode_forced?
      Rails.logger.info "✅ Enterprise mode detected - skipping reconciliation"
      force_enterprise_features
      return
    end

    # Se não for enterprise forçado, executar lógica original apenas para community real
    return if ChatwootHub.pricing_plan != 'community'

    create_premium_config_reset_warning if premium_config_reset_required?
    reconcile_premium_config
    # NUNCA executar reconcile_premium_features em modo enterprise
    reconcile_premium_features unless enterprise_mode_forced?
    # ================================
  end

  private

  def enterprise_mode_forced?
    # Verificar se enterprise foi forçado manualmente
    plan_config = InstallationConfig.find_by(name: 'INSTALLATION_PRICING_PLAN')
    plan_config&.value == 'enterprise'
  end

  def force_enterprise_features
    # Em vez de remover features, garantir que estejam ativas
    premium_features = %w[
      disable_branding audit_logs response_bot sla captain_integration
      custom_roles help_center_embedding_search captain_integration_v2
    ]

    Account.find_in_batches do |accounts|
      accounts.each do |account|
        missing_features = premium_features - account.enabled_features.keys
        if missing_features.any?
          account.enable_features!(*missing_features)
          Rails.logger.info "✅ Re-enabled features for account #{account.id}: #{missing_features.join(', ')}"
        end
      end
    end
  end

  def config_path
    @config_path ||= Rails.root.join('enterprise/config')
  end

  def premium_config
    @premium_config ||= YAML.safe_load(File.read("#{config_path}/premium_installation_config.yml")).freeze
  rescue => e
    Rails.logger.warn "Could not load premium config: #{e.message}"
    []
  end

  def remove_premium_config_reset_warning
    Redis::Alfred.delete(Redis::Alfred::CHATWOOT_INSTALLATION_CONFIG_RESET_WARNING)
  end

  def create_premium_config_reset_warning
    Redis::Alfred.set(Redis::Alfred::CHATWOOT_INSTALLATION_CONFIG_RESET_WARNING, true)
  end

  def premium_config_reset_required?
    return false if enterprise_mode_forced?  # Nunca resetar em modo enterprise forçado

    premium_config.any? do |config|
      config = config.with_indifferent_access
      existing_config = InstallationConfig.find_by(name: config[:name])
      existing_config&.value != config[:value] if existing_config.present?
    end
  end

  def reconcile_premium_config
    return if enterprise_mode_forced?  # Nunca reconciliar configs em modo enterprise forçado

    premium_config.each do |config|
      new_config = config.with_indifferent_access
      existing_config = InstallationConfig.find_by(name: new_config[:name])
      next if existing_config&.value == new_config[:value]
      existing_config&.update!(value: new_config[:value])
    end
  end

  def premium_features
    @premium_features ||= YAML.safe_load(File.read("#{config_path}/premium_features.yml")).freeze
  rescue => e
    Rails.logger.warn "Could not load premium features: #{e.message}"
    []
  end

  def reconcile_premium_features
    # ===== MÉTODO MAIS PERIGOSO - NEUTRALIZADO =====
    Rails.logger.info "🚫 reconcile_premium_features bypassed - enterprise mode"
    return if enterprise_mode_forced?

    # Só executar se realmente for community genuíno (não forçado)
    Account.find_in_batches do |accounts|
      accounts.each do |account|
        account.disable_features!(*premium_features)
      end
    end
    # ==============================================
  end
end
