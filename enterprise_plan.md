🔓 Tutorial: Desbloqueando Chatwoot Enterprise
📋 Objetivo
Ativar todas as features Enterprise do Chatwoot de forma permanente, incluindo onboarding automático e proteção contra reset.
🎯 Funcionalidades Desbloqueadas

✅ Disable Branding
✅ Audit Logs
✅ SLA Policies
✅ Custom Roles
✅ Captain Integration (IA)
✅ Response Bot
✅ 1000 agentes por conta
✅ Onboarding sempre ativo
✅ Proteção contra reset


📝 Arquivos Modificados

1. Migration Enterprise
Arquivo: db/migrate/xxxxx_enable_enterprise_features_by_default.rb

bash# Gerar migration
rails generate migration EnableEnterpriseFeaturesByDefault

Adicionar no arquivo gerado:

###
rubyclass EnableEnterpriseFeaturesByDefault < ActiveRecord::Migration[7.1]
  def up
    # Configurar plano enterprise
    InstallationConfig.find_or_create_by(name: 'INSTALLATION_PRICING_PLAN') do |config|
      config.value = 'enterprise'
    end

    # Configurar quantidade alta de licenças
    InstallationConfig.find_or_create_by(name: 'INSTALLATION_PRICING_PLAN_QUANTITY') do |config|
      config.value = 1000
    end

    # Forçar onboarding para novas instalações
    begin
      Redis::Alfred.set(Redis::Alfred::CHATWOOT_INSTALLATION_ONBOARDING, true)
    rescue => e
      Rails.logger.warn "Could not set onboarding flag: #{e.message}"
    end

    # Ativar features para contas existentes
    Account.find_each do |account|
      enable_premium_features_for_account(account)
    end
  end

  private

  def enable_premium_features_for_account(account)
    premium_features = [
      'disable_branding', 'audit_logs', 'response_bot', 'sla',
      'captain_integration', 'custom_roles', 'help_center_embedding_search',
      'captain_integration_v2'
    ]

    account.enable_features!(*premium_features)
    account.update(limits: { agents: 1000 })
  end
end
###


2. Model Account
Arquivo: app/models/account.rb

Adicionar após a linha: after_destroy :remove_account_sequences
ruby# Hook para novas contas
after_create :enable_enterprise_features_by_default
Adicionar no final da classe (antes do último end):
rubyprivate

# ===== ENTERPRISE FEATURES HOOK =====
  def enable_enterprise_features_by_default
    premium_features = [
      'disable_branding', 'audit_logs', 'response_bot', 'sla',
      'captain_integration', 'custom_roles', 'help_center_embedding_search',
      'captain_integration_v2'
    ]

    # Ativar features da conta
    enable_features!(*premium_features)
    update(limits: { agents: 1000 })

    # ===== ADIÇÃO: GARANTIR CONFIGS GLOBAIS =====
    # Forçar configurações enterprise toda vez que conta é criada
    InstallationConfig.find_or_create_by(name: 'INSTALLATION_PRICING_PLAN').update(value: 'enterprise')
    InstallationConfig.find_or_create_by(name: 'INSTALLATION_PRICING_PLAN_QUANTITY').update(value: 1000)
    # ==========================================

  rescue => e
    Rails.logger.error "Failed to enable enterprise features for account #{id}: #{e.message}"
  end
  # ===================================

3. Routes - Proteção contra Reset
Arquivo: config/routes.rb
Adicionar logo após: Rails.application.routes.draw do
ruby# Bloqueio do botão refresh
get '/super_admin/settings/refresh', to: redirect('/super_admin/settings')

🔧 Implementação
Passo 1: Fazer as modificações
bash# 1. Gerar migration
rails generate migration EnableEnterpriseFeaturesByDefault

# 2. Editar os 3 arquivos conforme descrito acima

# 3. Executar migration
rails db:migrate
Passo 2: Build da imagem
bash# Build da imagem customizada
docker build -f docker/Dockerfile -t hamielh/chatwooth:latest . --progress=plain

# Push para DockerHub (opcional)
docker login
docker push hamielh/chatwooth:latest
Passo 3: Verificação
ruby# No console Rails
ChatwootApp.enterprise?                    # => true
ChatwootHub.pricing_plan                  # => "enterprise"
ChatwootHub.pricing_plan_quantity         # => 1000
Account.first.feature_enabled?('sla')     # => true

📁 Estrutura Final
projeto/
├── db/migrate/
│   └── xxxxx_enable_enterprise_features_by_default.rb  ← Criado
├── app/models/
│   └── account.rb                                      ← Modificado
└── config/
    └── routes.rb                                       ← Modificado

🎯 Resultado

Instalações novas: Onboarding + Enterprise automático
Contas criadas: Features premium ativas desde o início
Botão Refresh: Desabilitado (só recarrega a página)
Limites: 1000 agentes por conta
Branding: Removido automaticamente
