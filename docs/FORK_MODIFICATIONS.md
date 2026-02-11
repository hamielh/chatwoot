# Chatwoot Fork - Documentacao Completa de Modificacoes

Documentacao completa de TODAS as modificacoes customizadas implementadas neste fork em relacao ao Chatwoot oficial (upstream `chatwoot/chatwoot` branch `develop`).

**Branch base:** `staging`
**Upstream:** `chatwoot/chatwoot` v4.8.0

---

## Sumario

1. [WhatsApp API via Quepasa](#1-whatsapp-api-via-quepasa)
2. [Bot Toggle por Conversa](#2-bot-toggle-por-conversa)
3. [Bot nas Automacoes](#3-bot-nas-automacoes)
4. [Chat Agents (Agentes IA Internos)](#4-chat-agents-agentes-ia-internos)
5. [Sidebar Apps (Aplicativos Customizados)](#5-sidebar-apps-aplicativos-customizados)
6. [Sidebar Configuravel (Super Admin)](#6-sidebar-configuravel-super-admin)
7. [Enterprise Bypass](#7-enterprise-bypass)
8. [Audio Duration (PTT WhatsApp)](#8-audio-duration-ptt-whatsapp)
9. [Quepasa Config (Super Admin)](#9-quepasa-config-super-admin)
10. [Scripts e Documentacao](#10-scripts-e-documentacao)
11. [Resumo de Todos os Endpoints Custom](#11-resumo-de-todos-os-endpoints-custom)
12. [Resumo de Todos os Arquivos Modificados](#12-resumo-de-todos-os-arquivos-modificados)

---

## 1. WhatsApp API via Quepasa

Canal customizado que conecta ao **Quepasa** para envio/recebimento de mensagens WhatsApp via QR Code. Substitui a necessidade de WhatsApp Cloud API (Meta) ou Twilio.

### Arquitetura

```
WhatsApp <-> Quepasa Server <-> Chatwoot (Channel::WhatsappApi)
```

- Quepasa roda como servico separado (ex: Docker)
- Chatwoot se conecta via API REST do Quepasa
- Webhook bidirecional: Quepasa envia mensagens para Chatwoot, Chatwoot envia respostas via API do Quepasa

### Funcionalidades

- Conexao via QR Code (scan pelo navegador)
- Envio e recebimento de mensagens de texto
- Envio e recebimento de anexos (imagens, audio, video, documentos, localizacao)
- Audio PTT (Push-to-Talk) com waveform nativo do WhatsApp
- Suporte a grupos (com opcao de ignorar)
- Avatar automatico do contato
- Read receipts (checks azuis) automaticos quando cliente responde
- Reply/quote de mensagens
- Reacoes
- Deteccao de mensagens do historico (ignoradas)
- Mensagens de grupo com nome do participante

### Arquivos Criados

| Arquivo | Descricao |
|---------|-----------|
| `app/models/channel/whatsapp_api.rb` | Model do canal (`Channel::WhatsappApi`) |
| `app/controllers/api/v1/accounts/channels/whatsapp_api_controller.rb` | Controller: scan, info, connect, disconnect, settings |
| `app/controllers/api/v1/webhooks/whatsapp_api_controller.rb` | Webhook receiver para mensagens do Quepasa |
| `app/services/whatsapp_api/incoming_message_service.rb` | Servico de processamento de mensagens recebidas |
| `app/services/whatsapp_api/send_on_whatsapp_api_service.rb` | Servico de envio de mensagens via Quepasa |
| `app/jobs/webhooks/whatsapp_api_events_job.rb` | Job assincrono para processar webhooks |
| `db/migrate/20251115000001_create_channel_whatsapp_api.rb` | Migration: tabela `channel_whatsapp_api` |
| `db/migrate/..._change_phone_number_null.rb` | Migration: permite phone_number null |
| `app/javascript/.../channels/WhatsappApi.vue` | Tela de criacao da inbox |
| `app/javascript/.../components/WhatsAppApiConnection.vue` | Componente de conexao/QR Code nas settings |

### Arquivos Modificados

| Arquivo | Modificacao |
|---------|-------------|
| `app/models/account.rb` | `has_many :whatsapp_api_channels` |
| `app/models/inbox.rb` | Suporte ao canal WhatsappApi |
| `app/jobs/send_reply_job.rb` | Mapeamento `Channel::WhatsappApi => WhatsappApi::SendOnWhatsappApiService` |
| `app/controllers/api/v1/accounts/inboxes_controller.rb` | `whatsapp_api` nos tipos permitidos + mapeamento |
| `app/helpers/api/v1/inboxes_helper.rb` | Mapeamento do canal no helper |
| `app/services/contacts/contactable_inboxes_service.rb` | Metodo `whatsapp_api_contactable_inbox` |
| `app/builders/contact_inbox_builder.rb` | Suporte ao WhatsappApi |
| `app/views/api/v1/models/_inbox.json.jbuilder` | Serializacao do canal |
| `app/javascript/dashboard/helper/inbox.js` | `WHATSAPP_API` type + icones (fill/line) |
| `app/javascript/shared/mixins/inboxMixin.js` | `isAWhatsAppApiChannel` + feature maps |
| `app/javascript/dashboard/composables/useInbox.js` | `isAWhatsAppChannel` inclui WhatsappApi |
| `app/javascript/.../inbox/ChannelFactory.vue` | Registra canal no factory |
| `app/javascript/.../inbox/channels/Whatsapp.vue` | Opcao "WhatsApp API" no selector de provider |
| `app/javascript/.../inbox/Settings.vue` | Aba "WhatsApp" nas settings da inbox |
| `app/javascript/.../inbox/components/ChannelName.vue` | Nome do canal |
| `app/javascript/.../NewConversation/helpers/composeConversationHelper.js` | Suporte ao canal em nova conversa |
| `app/javascript/.../captain/assistant/InboxCard.vue` | Suporte ao canal no Captain |
| `config/routes.rb` | Rotas: scan, info, update_connection, disconnect, update_settings, webhook |
| `app/javascript/dashboard/i18n/locale/en/inboxMgmt.json` | Traducoes completas |

### API Endpoints

#### Criar inbox

```
POST /api/v1/accounts/{account_id}/inboxes
```

```json
{
  "name": "WhatsApp Vendas",
  "channel": {
    "type": "whatsapp_api"
  }
}
```

#### Gerar QR Code

```
GET /api/v1/accounts/{account_id}/channels/whatsapp_api/{channel_id}/scan
```

Retorna imagem PNG do QR Code.

#### Verificar conexao

```
GET /api/v1/accounts/{account_id}/channels/whatsapp_api/{channel_id}/info
```

```json
{
  "verified": true,
  "connected": true,
  "wid": "5511999999999@s.whatsapp.net"
}
```

#### Salvar conexao

```
POST /api/v1/accounts/{account_id}/channels/whatsapp_api/{channel_id}/update_connection
```

```json
{
  "connection_info": {
    "wid": "5511999999999@s.whatsapp.net",
    "token": "abc123",
    "verified": true
  }
}
```

#### Desconectar

```
DELETE /api/v1/accounts/{account_id}/channels/whatsapp_api/{channel_id}/disconnect
```

#### Configuracoes (ignorar grupos)

```
POST /api/v1/accounts/{account_id}/channels/whatsapp_api/{channel_id}/update_settings
```

```json
{
  "ignore_groups": true
}
```

#### Webhook (receber mensagens do Quepasa)

```
POST /api/v1/webhooks/whatsapp_api/{inbox_id}
```

Configurado automaticamente ao conectar via QR Code.

### Fluxo de Setup Completo

1. Criar inbox com `channel.type = "whatsapp_api"`
2. Acessar settings da inbox → aba "WhatsApp"
3. Clicar "Connect WhatsApp" → escanear QR Code
4. Quepasa valida conexao → `update_connection` salva dados
5. Webhook configurado automaticamente no Quepasa
6. (Opcional) Criar Agent Bot e vincular ao inbox
7. Mensagens fluem bidirecionalmente

### Detalhes Tecnicos do IncomingMessageService

- **Deduplicacao:** Verifica `Message.find_by(source_id:)` antes de criar
- **Grupos:** Detecta `@g.us` no chat_id, prefixa mensagem com `*NomeParticipante:*`
- **Avatar:** Busca via `/picinfo/{phone}` do Quepasa, trata 9o digito BR
- **Anexos:** Download via `/download/{message_id}`, suporta image/audio/video/document/location
- **Localizacao:** Cria attachment com `coordinates_lat`, `coordinates_long`, `external_url`
- **Read Receipts:** Quando cliente responde, marca todas as outgoing anteriores como `read`
- **Reply:** Mapeia `inreply` → `in_reply_to` via source_id
- **Reacoes:** Detecta `inreaction` e prefixa com "reagiu com"

### Detalhes Tecnicos do SendOnWhatsappApiService

- **Envio:** POST para `/v3/bot/{token}/send` com header `X-QUEPASA-CHATID`
- **Anexos:** Converte para base64 no formato `data:MIME;base64,DATA`
- **Audio PTT:** Converte qualquer `audio/*` para `audio/ogg; codecs=opus` (Quepasa detecta PTT)
- **Grupos:** Usa sufixo `@g.us` vs `@s.whatsapp.net`
- **Reply:** Envia `inreply` com source_id da mensagem original
- **Status:** Atualiza para `delivered` ao enviar, `failed` em caso de erro

---

## 2. Bot Toggle por Conversa

Permite ativar/desativar o bot (webhook) por conversa individual. Quando desativado, o bot NAO recebe webhooks de mensagens daquela conversa.

### Arquitetura

- Coluna `bot_enabled` (boolean, default: true) na tabela `conversations`
- Toggle na sidebar da conversa (icone de robo + switch)
- Guards no `AgentBotListener` e `BotProcessorService`

### Arquivos Criados

| Arquivo | Descricao |
|---------|-----------|
| `db/migrate/20260126120000_add_bot_enabled_to_conversations.rb` | Migration: `bot_enabled` boolean, default true |

### Arquivos Modificados

| Arquivo | Modificacao |
|---------|-------------|
| `app/models/conversation.rb` | `bot_enabled` no `list_of_keys` (WebSocket dispatch) |
| `app/controllers/api/v1/accounts/conversations_controller.rb` | Action `toggle_bot` |
| `app/listeners/agent_bot_listener.rb` | Guard `return unless message.conversation.bot_enabled?` em `message_created` e `message_updated` |
| `lib/integrations/bot_processor_service.rb` | Guard `return unless conversation.bot_enabled?` em `should_run_processor?` |
| `app/views/api/v1/conversations/partials/_conversation.json.jbuilder` | `json.bot_enabled conversation.bot_enabled` |
| `config/routes.rb` | `post :toggle_bot` (member route da conversation) |
| `app/javascript/dashboard/api/inbox/conversation.js` | Metodo `toggleBot({ conversationId, botEnabled })` |
| `app/javascript/dashboard/store/mutation-types.js` | `TOGGLE_BOT_ENABLED` |
| `app/javascript/dashboard/store/modules/conversations/actions.js` | Action `toggleBotEnabled` |
| `app/javascript/dashboard/store/modules/conversations/index.js` | Mutation `TOGGLE_BOT_ENABLED` |
| `app/javascript/dashboard/routes/dashboard/conversation/contact/ContactInfo.vue` | Toggle UI: icone robo + "Habilitar Bot" + ToggleSwitch |
| `app/javascript/dashboard/routes/dashboard/conversation/ContactPanel.vue` | Passa `conversation-id` prop ao ContactInfo |
| `app/javascript/dashboard/i18n/locale/en/contact.json` | `"BOT_TOGGLE": "Habilitar Bot"` |

### API

#### Toggle bot

```
POST /api/v1/accounts/{account_id}/conversations/{conversation_id}/toggle_bot
```

```json
{
  "bot_enabled": false
}
```

**Response:** `200 OK`

#### Verificar estado

O campo `bot_enabled` e retornado em qualquer endpoint que retorna dados da conversa:

```json
{
  "id": 42,
  "status": "open",
  "bot_enabled": true
}
```

### Comportamento

| bot_enabled | Webhook AgentBot | BotProcessor (Dialogflow etc) |
|-------------|------------------|-------------------------------|
| `true` (padrao) | Dispara | Processa |
| `false` | **Bloqueado** | **Bloqueado** |

**Eventos NAO bloqueados** (mesmo com bot_enabled=false):
- `conversation_resolved`
- `conversation_opened`

### UI

Na sidebar da conversa, abaixo dos dados do contato:
- Icone `i-lucide-bot` + label "Habilitar Bot" + ToggleSwitch
- Visivel apenas quando `conversationId` esta presente
- Atualiza via Vuex + API call

---

## 3. Bot nas Automacoes

O campo `bot_enabled` esta disponivel nas automacoes do Chatwoot como **condicao** e como **acao**.

### Arquivos Modificados

| Arquivo | Modificacao |
|---------|-------------|
| `app/models/automation_rule.rb` | `bot_enabled` em `conditions_attributes` + `change_bot_enabled` em `actions_attributes` |
| `lib/filters/filter_keys.yml` | Filtro `bot_enabled` (boolean, equal_to/not_equal_to) |
| `app/services/action_service.rb` | Metodo `change_bot_enabled(params)` com extracao de hash e guard |
| `app/javascript/.../automation/constants.js` | Condicao `bot_enabled` + acao `change_bot_enabled` em todos os 5 eventos |
| `app/javascript/dashboard/helper/automationHelper.js` | `bot_enabled` em conditionFilterMaps + `change_bot_enabled` em actionsMap |
| `app/javascript/dashboard/composables/useAutomationValues.js` | `botEnabledOptions` computed (Ativado/Desativado) |
| `app/javascript/dashboard/i18n/locale/en/automation.json` | Traducoes: BOT_ENABLED, CHANGE_BOT_ENABLED, BOT_ENABLED_TYPES |

### Como usar

**Bot como CONDICAO:**

```json
{
  "attribute_key": "bot_enabled",
  "filter_operator": "equal_to",
  "values": [false]
}
```

**Bot como ACAO:**

```json
{
  "action_name": "change_bot_enabled",
  "action_params": [false]
}
```

### Exemplo: Time Humano → Desativa Bot

```bash
curl -X POST 'http://localhost:3000/api/v1/accounts/1/automation_rules' \
  -H 'api_access_token: TOKEN' \
  -H 'Content-Type: application/json' \
  -d '{
    "automation_rule": {
      "name": "Time Humano - Desativa Bot",
      "event_name": "conversation_updated",
      "conditions": [
        {
          "attribute_key": "team_id",
          "filter_operator": "equal_to",
          "values": [1],
          "query_operator": null
        }
      ],
      "actions": [
        {
          "action_name": "change_bot_enabled",
          "action_params": [false]
        }
      ]
    }
  }'
```

### Exemplo: Time IA → Ativa Bot

```bash
curl -X POST 'http://localhost:3000/api/v1/accounts/1/automation_rules' \
  -H 'api_access_token: TOKEN' \
  -H 'Content-Type: application/json' \
  -d '{
    "automation_rule": {
      "name": "Time IA - Ativa Bot",
      "event_name": "conversation_updated",
      "conditions": [
        {
          "attribute_key": "team_id",
          "filter_operator": "equal_to",
          "values": [2],
          "query_operator": null
        }
      ],
      "actions": [
        {
          "action_name": "change_bot_enabled",
          "action_params": [true]
        }
      ]
    }
  }'
```

### Cuidado: Regras Circulares

**NAO use regras bidirecionais simultaneas:**

```
Rule 1: team=Humano → bot OFF
Rule 2: team=IA    → bot ON
Rule 3: bot ON     → assign team IA      ← CONFLITA
Rule 4: bot OFF    → assign team Humano  ← CONFLITA
```

As automacoes checam o estado ATUAL, nao o que mudou. Regras 3+4 com 1+2 criam loop.

**Recomendacao:** Use apenas uma direcao:

```
Rule 1: team=Humano → bot OFF
Rule 2: team=IA     → bot ON
```

### Detalhes Tecnicos do ActionService

```ruby
def change_bot_enabled(params)
  value = params[0]
  value = value['id'] if value.is_a?(Hash)  # Dropdown salva como {id: false, name: "Desativado"}
  value = ActiveModel::Type::Boolean.new.cast(value)
  return if @conversation.bot_enabled == value  # Guard contra same-value (previne loops)
  @conversation.update!(bot_enabled: value)
end
```

---

## 4. Chat Agents (Agentes IA Internos)

Sistema de agentes de chat internos com webhook externo. Permite criar "assistentes IA" que os agentes podem conversar dentro do Chatwoot. Cada agente tem um webhook que recebe as mensagens e retorna respostas.

### Arquitetura

```
Agente Humano (UI) → Chat Agent → Webhook (IA externa) → Callback API → WebSocket → UI
```

- Chat Agents sao configurados por conta
- Cada agent tem: titulo, icone, webhook_url, webhook_params, roles permitidos
- Mensagens sao processadas assincronamente via job
- Respostas chegam via callback API + broadcast WebSocket

### Arquivos Criados

| Arquivo | Descricao |
|---------|-----------|
| `app/models/chat_agent.rb` | Model com validacoes, scopes (enabled, ordered, for_role) |
| `app/models/chat_agent_message.rb` | Model de mensagens (roles: user/assistant, statuses: pending/processing/completed/error) |
| `app/controllers/api/v1/accounts/chat_agents_controller.rb` | CRUD de agentes |
| `app/controllers/api/v1/accounts/chat_agents/messages_controller.rb` | Send, index, create (callback), destroy_all |
| `app/jobs/chat_agents/webhook_job.rb` | Job assincrono que chama webhook + broadcast |
| `app/channels/chat_agents_channel.rb` | ActionCable channel para real-time |
| `app/javascript/dashboard/api/chatAgents.js` | API client (get, getMessages, sendMessage, clearMessages) |
| `app/javascript/dashboard/store/modules/chatAgents.js` | Vuex store completo |
| `app/javascript/dashboard/store/modules/chatAgentUI.js` | UI state (open/close) |
| `app/javascript/.../chatAgent/ChatAgentContainer.vue` | Container principal do chat |
| `app/javascript/.../chatAgent/ChatAgentLauncher.vue` | Botao launcher flutuante |
| `app/javascript/.../settings/chatAgents/Index.vue` | Pagina de listagem |
| `app/javascript/.../settings/chatAgents/ChatAgentRow.vue` | Linha na tabela |
| `app/javascript/.../settings/chatAgents/ChatAgentModal.vue` | Modal de criacao/edicao |
| `app/javascript/dashboard/i18n/locale/en/chatAgents.json` | Traducoes |
| `app/views/api/v1/accounts/chat_agents/*.json.jbuilder` | Views de serializacao |
| `app/views/api/v1/models/_chat_agent.json.jbuilder` | Partial do model |
| `app/views/api/v1/models/_chat_agent_message.json.jbuilder` | Partial de mensagem |
| `db/migrate/20251125014155_create_chat_agents.rb` | Migration: tabela chat_agents |
| `db/migrate/20251125014218_create_chat_agent_messages.rb` | Migration: tabela chat_agent_messages |
| `db/migrate/..._add_async_fields_to_chat_agents.rb` | Migration: webhook_token, webhook_params |
| `db/migrate/..._add_async_fields_to_chat_agent_messages.rb` | Migration: conversation_id, status |
| `db/migrate/..._change_default_icon_for_chat_agents.rb` | Migration: default icon |
| `db/migrate/..._add_webhook_params_to_chat_agents.rb` | Migration: webhook_params jsonb |

### Arquivos Modificados

| Arquivo | Modificacao |
|---------|-------------|
| `app/models/account.rb` | `has_many :chat_agents, :chat_agent_messages` |
| `app/models/user.rb` | `has_many :chat_agents, :chat_agent_messages` |
| `app/javascript/dashboard/store/index.js` | Registra chatAgents + chatAgentUI modules |
| `app/javascript/dashboard/store/mutation-types.js` | 9 mutation types para chat agents |
| `app/javascript/dashboard/helper/actionCable.js` | Handler `onChatAgentMessage` para WebSocket |
| `app/javascript/dashboard/featureFlags.js` | `CHAT_AGENTS` flag |
| `app/javascript/dashboard/i18n/locale/en/index.js` | Import chatAgents translations |
| `app/javascript/.../Dashboard.vue` | ChatAgentLauncher no layout |
| `app/javascript/.../settings/integrations/Index.vue` | Card de Chat Agents na pagina de integracoes |
| `app/javascript/.../settings/integrations/integrations.routes.js` | Rotas de settings |
| `config/routes.rb` | Rotas CRUD + messages + send + destroy_all |
| `config/features.yml` | Feature flag `chat_agents: enabled: true` |

### API Endpoints

#### CRUD de Chat Agents

```
GET    /api/v1/accounts/{id}/chat_agents
POST   /api/v1/accounts/{id}/chat_agents
GET    /api/v1/accounts/{id}/chat_agents/{id}
PATCH  /api/v1/accounts/{id}/chat_agents/{id}
DELETE /api/v1/accounts/{id}/chat_agents/{id}
```

**Criar:**

```json
{
  "chat_agent": {
    "title": "Assistente IA",
    "webhook_url": "https://meu-bot.com/chat",
    "description": "Assistente para ajudar agentes",
    "icon": "i-lucide-bot",
    "position": 0,
    "enabled": true,
    "allowed_roles": [],
    "webhook_params": {
      "model": "gpt-4",
      "temperature": "0.7"
    }
  }
}
```

#### Mensagens

```
GET    /api/v1/accounts/{id}/chat_agents/{id}/messages       # Listar
POST   /api/v1/accounts/{id}/chat_agents/{id}/messages/send  # Enviar (usuario)
POST   /api/v1/accounts/{id}/chat_agents/{id}/messages       # Callback (bot responde)
DELETE /api/v1/accounts/{id}/chat_agents/{id}/messages        # Limpar historico
```

**Enviar mensagem:**

```json
{
  "message": "Como posso ajudar o cliente com reembolso?"
}
```

**Callback (bot responde):**

```json
{
  "content": "Para reembolso, siga os passos: 1. Acesse..."
}
```

### Payload do Webhook

Quando o usuario envia mensagem, o job chama o webhook com:

```json
{
  "action": "message",
  "message": "texto da mensagem",
  "custom_params": { "model": "gpt-4" },
  "user_id": 1,
  "account_id": 1,
  "agent_id": 5
}
```

Para limpar historico:

```json
{
  "action": "clear_history",
  "message": "",
  "custom_params": { "model": "gpt-4" },
  "agent_id": 5,
  "account_id": 1,
  "user_id": 1
}
```

### WebSocket

Canal: `account_{account_id}`
Evento: `chat_agent.message_received`

```json
{
  "id": 123,
  "chat_agent_id": 5,
  "content": "Resposta do bot...",
  "role": "assistant",
  "status": "completed",
  "created_at": 1706000000,
  "account_id": 1
}
```

### Feature Flag

Requer feature `chat_agents` habilitada na conta. Configurado em `config/features.yml` como `enabled: true` por padrao.

---

## 5. Sidebar Apps (Aplicativos Customizados)

Sistema de aplicativos iframe embeddaveis na sidebar do Chatwoot. Permite criar apps customizados que aparecem no menu lateral ou na raiz da sidebar.

### Arquitetura

- Cada app tem: titulo, URL (iframe), icone, posicao, roles permitidos, display_location
- `display_location`: `"apps_menu"` (dentro do menu Apps) ou `"root"` (item raiz na sidebar)
- Apps sao filtrados por role do usuario

### Arquivos Criados

| Arquivo | Descricao |
|---------|-----------|
| `app/models/sidebar_app.rb` | Model com validacoes e scopes |
| `app/controllers/api/v1/accounts/sidebar_apps_controller.rb` | CRUD completo |
| `app/javascript/dashboard/api/sidebarApps.js` | API client |
| `app/javascript/dashboard/store/modules/sidebarApps.js` | Vuex store |
| `app/javascript/.../sidebar-apps/Index.vue` | Pagina container |
| `app/javascript/.../sidebar-apps/SidebarAppFrame.vue` | Iframe do app |
| `app/javascript/.../sidebar-apps/sidebarApps.routes.js` | Rotas |
| `app/javascript/.../settings/apps/CustomApps/Index.vue` | Settings - listagem |
| `app/javascript/.../settings/apps/CustomApps/CustomAppModal.vue` | Settings - modal criar/editar |
| `app/javascript/.../settings/apps/CustomApps/CustomAppsRow.vue` | Settings - linha na tabela |
| `app/javascript/dashboard/i18n/locale/en/sidebarApps.json` | Traducoes |
| `app/views/api/v1/accounts/sidebar_apps/*.json.jbuilder` | Views de serializacao |
| `app/views/api/v1/models/_sidebar_app.json.jbuilder` | Partial |
| `db/migrate/20251124195813_create_sidebar_apps.rb` | Migration: tabela sidebar_apps |
| `db/migrate/20251124204238_add_icon_to_sidebar_apps.rb` | Migration: coluna icon |
| `spec/factories/sidebar_app.rb` | Factory para testes |

### Arquivos Modificados

| Arquivo | Modificacao |
|---------|-------------|
| `app/models/account.rb` | `has_many :sidebar_apps` |
| `app/models/user.rb` | `has_many :sidebar_apps` |
| `app/javascript/.../sidebar/Sidebar.vue` | Renderiza apps dinamicamente (root + apps_menu) |
| `app/javascript/dashboard/store/index.js` | Registra sidebarApps module |
| `app/javascript/dashboard/store/mutation-types.js` | 5 mutation types |
| `app/javascript/.../dashboard.routes.js` | Rotas de sidebar apps |
| `app/javascript/dashboard/i18n/locale/en/index.js` | Import sidebarApps |
| `app/javascript/dashboard/i18n/locale/en/settings.json` | "Apps" no menu |
| `config/routes.rb` | `resources :sidebar_apps` |

### API Endpoints

```
GET    /api/v1/accounts/{id}/sidebar_apps
POST   /api/v1/accounts/{id}/sidebar_apps
GET    /api/v1/accounts/{id}/sidebar_apps/{id}
PATCH  /api/v1/accounts/{id}/sidebar_apps/{id}
DELETE /api/v1/accounts/{id}/sidebar_apps/{id}
```

**Criar:**

```json
{
  "sidebar_app": {
    "title": "CRM Dashboard",
    "url": "https://crm.empresa.com/embed",
    "icon": "i-lucide-layout-dashboard",
    "position": 0,
    "display_location": "root",
    "allowed_roles": ["administrator", "agent"]
  }
}
```

| Campo | Tipo | Descricao |
|-------|------|-----------|
| title | string | Nome do app |
| url | string | URL do iframe |
| icon | string | Classe do icone (Lucide) |
| position | integer | Ordem de exibicao |
| display_location | string | `"root"` ou `"apps_menu"` |
| allowed_roles | array | Roles permitidos (vazio = todos) |

---

## 6. Sidebar Configuravel (Super Admin)

Controle global (Super Admin) de quais secoes aparecem na sidebar de conversa. Permite ocultar/exibir secoes via `InstallationConfig`.

### Configuracoes Disponiveis

| Config | Descricao | Default |
|--------|-----------|---------|
| `SIDEBAR_CONVERSATION_ACTIONS` | Acoes da conversa | `true` |
| `SIDEBAR_CONVERSATION_PARTICIPANTS` | Participantes | `true` |
| `SIDEBAR_CONVERSATION_INFO` | Info da conversa | `true` |
| `SIDEBAR_CONTACT_ATTRIBUTES` | Atributos do contato | `true` |
| `SIDEBAR_PREVIOUS_CONVERSATION` | Conversas anteriores | `true` |
| `SIDEBAR_MACROS` | Macros | `true` |
| `SIDEBAR_LINEAR_ISSUES` | Issues do Linear | `true` |
| `SIDEBAR_SHOPIFY_ORDERS` | Pedidos Shopify | `true` |
| `SIDEBAR_CONTACT_NOTES` | Notas do contato | `true` |

### Arquivos Modificados

| Arquivo | Modificacao |
|---------|-------------|
| `app/controllers/dashboard_controller.rb` | 9 configs no `globalConfig` do frontend |
| `app/controllers/super_admin/app_configs_controller.rb` | Grupo `conversation_sidebar` no Super Admin |
| `app/helpers/super_admin/features.yml` | Secao `conversation_sidebar` |
| `config/installation_config.yml` | 9 configs `SIDEBAR_*` |
| `app/javascript/shared/store/globalConfig.js` | Parse das 9 configs |
| `app/javascript/.../conversation/ContactPanel.vue` | Condiciona exibicao das secoes |

### Como Configurar

1. Acessar Super Admin → App Configs → Conversation Sidebar
2. Definir cada secao como `true` (visivel) ou `false` (oculto)
3. As mudancas aplicam globalmente para todos os usuarios

---

## 7. Enterprise Bypass

Desabilita as verificacoes de plano/licenca Enterprise para manter todas as features premium ativas permanentemente.

### O que faz

- Neutraliza o job `CheckNewVersionsJob` que sincroniza plano com servidor da Chatwoot Inc
- Neutraliza o `ReconcilePlanConfigService` que desabilita features premium em planos community
- Ativa features enterprise automaticamente ao criar novas contas
- Forca `INSTALLATION_PRICING_PLAN = 'enterprise'` e `INSTALLATION_PRICING_PLAN_QUANTITY = 1000`

### Features Enterprise Mantidas Ativas

- `disable_branding` — Remove branding Chatwoot
- `audit_logs` — Logs de auditoria
- `response_bot` — Bot de respostas
- `sla` — SLA management
- `captain_integration` — Captain IA v1
- `captain_integration_v2` — Captain IA v2
- `custom_roles` — Roles customizados
- `help_center_embedding_search` — Busca embeddings no Help Center

### Arquivos Modificados

| Arquivo | Modificacao |
|---------|-------------|
| `enterprise/app/jobs/enterprise/internal/check_new_versions_job.rb` | Bypass total: `update_plan_info`, `reconcile_premium_config_and_features` desabilitados. Executa `maintain_enterprise_config` que forca enterprise. |
| `enterprise/app/services/internal/reconcile_plan_config_service.rb` | Neutralizado: `reconcile_premium_features` nao remove features. `force_enterprise_features` re-ativa features em todas as contas. Guards `enterprise_mode_forced?` em todos os metodos destrutivos. |
| `app/models/account.rb` | `after_create :enable_enterprise_features_by_default` — ativa features premium + forca configs enterprise ao criar conta |

### Arquivos Criados

| Arquivo | Descricao |
|---------|-----------|
| `db/migrate/...200429_enable_enterprise_features_by_default.rb` | Migration de suporte |

---

## 8. Audio Duration (PTT WhatsApp)

Exibe a duracao dos audios recebidos via WhatsApp na interface, com waveform nativo.

### Problema

O Chatwoot oficial nao exibia a duracao de audios recebidos. O elemento `<audio>` em muitos casos retornava `Infinity` ou `NaN` como duracao, especialmente para audios OGG/Opus do WhatsApp.

### Solucao

- O `IncomingMessageService` salva a duracao (campo `seconds` do Quepasa) no metadata do blob do ActiveStorage
- O model `Attachment` retorna `duration` no JSON de audio
- O componente `Audio.vue` usa a duracao do backend como prioridade sobre a do elemento `<audio>`

### Arquivos Modificados

| Arquivo | Modificacao |
|---------|-------------|
| `app/models/attachment.rb` | Retorna `duration: file.metadata[:duration]` no `push_audio_event_data` |
| `app/services/whatsapp_api/incoming_message_service.rb` | Salva `blob.metadata['duration'] = duration.to_f` no `set_attachment_metadata` |
| `app/javascript/.../message/chips/Audio.vue` | Usa `attachment.duration` do backend; watch para mensagens via WebSocket; fallback para duracao do `<audio>` element |

---

## 9. Quepasa Config (Super Admin)

Configuracoes do servidor Quepasa no painel Super Admin.

### Configuracoes

| Config | Descricao |
|--------|-----------|
| `QUEPASA_API_URL` | URL base da API Quepasa (ex: `http://localhost:31000`) |
| `QUEPASA_API_USER` | Usuario padrao para autenticacao na API |

### Arquivos Modificados

| Arquivo | Modificacao |
|---------|-------------|
| `app/controllers/super_admin/app_configs_controller.rb` | Grupo `quepasa` com configs |
| `app/helpers/super_admin/features.yml` | Secao `quepasa` |
| `config/installation_config.yml` | `QUEPASA_API_URL` e `QUEPASA_API_USER` |

---

## 10. Scripts e Documentacao

### Scripts Criados

| Arquivo | Descricao |
|---------|-----------|
| `scripts/deploy-to-production.sh` | Script de deploy para producao |
| `scripts/docker-build.sh` | Build do Docker image |
| `scripts/docker-push.sh` | Push para Docker Hub |
| `scripts/update-fork.sh` | Atualiza fork do upstream |
| `start_chatwoot.sh` | Script de inicializacao |

### Documentacao Criada

| Arquivo | Descricao |
|---------|-----------|
| `docs/API_CUSTOM.md` | Documentacao das APIs customizadas (Bot Toggle, Automacoes, WhatsApp API) |
| `API_CUSTOM_APPS_LABELS.md` | Documentacao de apps e labels |
| `GEMINI.md` | Notas sobre integracao Gemini |
| `BRANCHES.md` | Documentacao das branches |
| `enterprise_plan.md` | Notas sobre plano enterprise |
| `quepasa/INTEGRACAO_CHATWOOT.md` | Guia completo de integracao Quepasa + Chatwoot |
| `quepasa/docs/CHAT_MANAGEMENT.md` | Gestao de chats no Quepasa |
| `quepasa/docs/CONTACT_MESSAGES.md` | Mensagens de contato |
| `quepasa/docs/SEND_LOCATION.md` | Envio de localizacao |
| `quepasa/docs/WAKEUP_TIMER.md` | Timer de wake-up |
| `quepasa/docs/WEBHOOK_SYSTEM_DOCUMENTATION.md` | Sistema de webhooks do Quepasa |
| `quepasa/docs/WHATSAPP_ADS_FIELDS_DOCUMENTATION.md` | Campos de anuncios WhatsApp |
| `quepasa/docs/group-leave.md` | Saida de grupos |
| `quepasa/docs/message-edit.md` | Edicao de mensagens |

### Outros Arquivos

| Arquivo | Descricao |
|---------|-----------|
| `chat.png` | Imagem para integracoes |
| `public/dashboard/images/integrations/chat_agents.png` | Icone Chat Agents |
| `public/dashboard/images/integrations/chat_agents-dark.png` | Icone Chat Agents (dark) |
| `public/dashboard/images/integrations/custom_apps.png` | Icone Custom Apps |
| `public/dashboard/images/integrations/custom_apps-dark.png` | Icone Custom Apps (dark) |

---

## 11. Resumo de Todos os Endpoints Custom

Todos os endpoints seguem o padrao: `/api/v1/accounts/{account_id}/...`

### Bot Toggle

| Metodo | Endpoint | Descricao |
|--------|----------|-----------|
| POST | `/conversations/{id}/toggle_bot` | Ativar/desativar bot na conversa |

### WhatsApp API (Quepasa)

| Metodo | Endpoint | Descricao |
|--------|----------|-----------|
| GET | `/channels/whatsapp_api/{id}/scan` | QR Code do WhatsApp |
| GET | `/channels/whatsapp_api/{id}/info` | Status da conexao |
| POST | `/channels/whatsapp_api/{id}/update_connection` | Salvar dados de conexao |
| DELETE | `/channels/whatsapp_api/{id}/disconnect` | Desconectar WhatsApp |
| POST | `/channels/whatsapp_api/{id}/update_settings` | Configuracoes (ignore groups) |
| POST | `/webhooks/whatsapp_api/{inbox_id}` | Webhook (receber mensagens) |

### Chat Agents

| Metodo | Endpoint | Descricao |
|--------|----------|-----------|
| GET | `/chat_agents` | Listar agentes |
| POST | `/chat_agents` | Criar agente |
| GET | `/chat_agents/{id}` | Ver agente |
| PATCH | `/chat_agents/{id}` | Atualizar agente |
| DELETE | `/chat_agents/{id}` | Deletar agente |
| GET | `/chat_agents/{id}/messages` | Listar mensagens |
| POST | `/chat_agents/{id}/messages/send` | Enviar mensagem (usuario) |
| POST | `/chat_agents/{id}/messages` | Criar mensagem (callback bot) |
| DELETE | `/chat_agents/{id}/messages` | Limpar historico |

### Sidebar Apps

| Metodo | Endpoint | Descricao |
|--------|----------|-----------|
| GET | `/sidebar_apps` | Listar apps |
| POST | `/sidebar_apps` | Criar app |
| GET | `/sidebar_apps/{id}` | Ver app |
| PATCH | `/sidebar_apps/{id}` | Atualizar app |
| DELETE | `/sidebar_apps/{id}` | Deletar app |

### Automacoes (campos custom)

| Campo | Tipo | Descricao |
|-------|------|-----------|
| `bot_enabled` | condicao | Filtrar por estado do bot |
| `change_bot_enabled` | acao | Alterar estado do bot |

---

## 12. Resumo de Todos os Arquivos Modificados

### Tabelas de Banco Criadas

| Tabela | Descricao |
|--------|-----------|
| `channel_whatsapp_api` | Canal WhatsApp API (Quepasa) |
| `chat_agents` | Agentes de chat IA |
| `chat_agent_messages` | Mensagens dos agentes |
| `sidebar_apps` | Apps customizados da sidebar |
| `conversations.bot_enabled` | Coluna adicionada |

### Contagem de Arquivos

| Tipo | Criados | Modificados |
|------|---------|-------------|
| Ruby (models, controllers, services, jobs) | ~20 | ~15 |
| Vue/JS (components, stores, helpers) | ~25 | ~20 |
| Migrations | ~10 | 0 |
| Config (routes, features, i18n) | ~5 | ~10 |
| Documentacao/Scripts | ~20 | 0 |
| **Total** | **~80** | **~45** |

### Estatisticas do Diff

```
126 files changed, 10375 insertions(+), 49 deletions(-)
```

---

## Notas de Manutencao

### Ao atualizar do upstream (merge)

1. Verificar conflitos em `config/routes.rb` (principal ponto de conflito)
2. Verificar `app/models/account.rb` (associacoes e enterprise bypass)
3. Verificar `app/javascript/dashboard/store/index.js` (modules registrados)
4. Verificar `app/javascript/dashboard/helper/inbox.js` (INBOX_TYPES)
5. Verificar `db/schema.rb` (tabelas custom devem ser mantidas)
6. Verificar `enterprise/` (bypass deve ser preservado)
7. Rodar migrations: `bundle exec rails db:migrate`
8. Testar: WhatsApp API scan/send, Bot toggle, Chat Agents, Sidebar Apps

### Docker Build

```bash
docker build -f docker/Dockerfile -t hamielh/chatwooth:latest -t hamielh/chatwooth:4.8.1 .
docker push hamielh/chatwooth:latest && docker push hamielh/chatwooth:4.8.1
```
