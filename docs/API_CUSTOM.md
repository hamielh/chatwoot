# Chatwoot Custom API Documentation

Documentacao das features customizadas implementadas neste fork.

---

## Sumario

- [Bot Toggle (por conversa)](#bot-toggle-por-conversa)
- [Automacoes com Bot](#automacoes-com-bot)
- [Inbox WhatsApp API (Quepasa)](#inbox-whatsapp-api-quepasa)

---

## Bot Toggle (por conversa)

Permite ativar/desativar o bot (webhook) por conversa individual. Quando desativado, o bot nao recebe webhooks de mensagens daquela conversa.

### Toggle Bot

```
POST /api/v1/accounts/{account_id}/conversations/{conversation_id}/toggle_bot
```

**Headers:**
```
api_access_token: {token}
Content-Type: application/json
```

**Body:**
```json
{
  "bot_enabled": false
}
```

| Campo | Tipo | Obrigatorio | Descricao |
|-------|------|-------------|-----------|
| bot_enabled | boolean | sim | `true` ativa o bot, `false` desativa |

**Response:** `200 OK`

**Exemplo - Desativar bot:**
```bash
curl -X POST 'http://localhost:3000/api/v1/accounts/1/conversations/42/toggle_bot' \
  -H 'api_access_token: TOKEN' \
  -H 'Content-Type: application/json' \
  -d '{"bot_enabled": false}'
```

**Exemplo - Ativar bot:**
```bash
curl -X POST 'http://localhost:3000/api/v1/accounts/1/conversations/42/toggle_bot' \
  -H 'api_access_token: TOKEN' \
  -H 'Content-Type: application/json' \
  -d '{"bot_enabled": true}'
```

### Verificar estado do bot

O campo `bot_enabled` e retornado na resposta de qualquer endpoint que retorna dados da conversa:

```
GET /api/v1/accounts/{account_id}/conversations/{conversation_id}
```

**Resposta (trecho):**
```json
{
  "id": 42,
  "status": "open",
  "priority": null,
  "bot_enabled": true,
  ...
}
```

### Comportamento

| bot_enabled | Webhook | Bot processa mensagens |
|-------------|---------|----------------------|
| `true` (padrao) | Dispara normalmente | Sim |
| `false` | **NAO** dispara | Nao |

**Onde o bloqueio acontece:**
- `AgentBotListener` — bloqueia webhooks em `message_created` e `message_updated`
- `BotProcessorService` — bloqueia processamento (Dialogflow, etc.)

**Eventos NAO bloqueados (mesmo com bot_enabled=false):**
- `conversation_resolved`
- `conversation_opened`

---

## Automacoes com Bot

O campo `bot_enabled` esta disponivel nas automacoes do Chatwoot como **condicao** e como **acao**.

### Criar automacao via API

```
POST /api/v1/accounts/{account_id}/automation_rules
```

**Headers:**
```
api_access_token: {token}
Content-Type: application/json
```

### Exemplo 1: Time Humano atribuido → Desativar Bot

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

### Exemplo 2: Time IA atribuido → Ativar Bot

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

### Exemplo 3: Bot como condicao → Atribuir time

```bash
curl -X POST 'http://localhost:3000/api/v1/accounts/1/automation_rules' \
  -H 'api_access_token: TOKEN' \
  -H 'Content-Type: application/json' \
  -d '{
    "automation_rule": {
      "name": "Bot Desativado - Atribui Time Humano",
      "event_name": "conversation_updated",
      "conditions": [
        {
          "attribute_key": "bot_enabled",
          "filter_operator": "equal_to",
          "values": [false],
          "query_operator": null
        }
      ],
      "actions": [
        {
          "action_name": "assign_team",
          "action_params": [1]
        }
      ]
    }
  }'
```

### Referencia de campos

**Bot como CONDICAO (`conditions`):**

| Campo | Valor |
|-------|-------|
| attribute_key | `"bot_enabled"` |
| filter_operator | `"equal_to"` ou `"not_equal_to"` |
| values | `[true]` ou `[false]` |

**Bot como ACAO (`actions`):**

| Campo | Valor |
|-------|-------|
| action_name | `"change_bot_enabled"` |
| action_params | `[true]` para ativar, `[false]` para desativar |

### Eventos disponiveis

O `bot_enabled` funciona como condicao e acao em todos os eventos:

| Evento | Descricao |
|--------|-----------|
| `conversation_created` | Quando conversa e criada |
| `conversation_updated` | Quando conversa e atualizada (recomendado) |
| `conversation_opened` | Quando conversa e reaberta |
| `conversation_resolved` | Quando conversa e resolvida |
| `message_created` | Quando mensagem e criada |

### Cuidado: Regras circulares

**NAO use regras bidirecionais simultaneas.** Exemplo problematico:

```
Rule 1: team=Humano → bot OFF
Rule 2: team=IA    → bot ON
Rule 3: bot ON     → assign team IA      ← CONFLITA com Rule 2
Rule 4: bot OFF    → assign team Humano  ← CONFLITA com Rule 1
```

As regras 3 e 4 entram em conflito com 1 e 2 porque as automacoes checam o estado ATUAL da conversa, nao o que mudou.

**Recomendacao:** Use apenas uma direcao:

```
Rule 1: team=Humano → bot OFF  ✅
Rule 2: team=IA     → bot ON   ✅
```

O toggle na sidebar continua funcionando como override direto (sem automacao).

### Listar automacoes

```bash
curl 'http://localhost:3000/api/v1/accounts/1/automation_rules' \
  -H 'api_access_token: TOKEN'
```

### Atualizar automacao

```bash
curl -X PATCH 'http://localhost:3000/api/v1/accounts/1/automation_rules/{rule_id}' \
  -H 'api_access_token: TOKEN' \
  -H 'Content-Type: application/json' \
  -d '{
    "automation_rule": {
      "name": "Novo nome",
      "actions": [
        {
          "action_name": "change_bot_enabled",
          "action_params": [true]
        }
      ]
    }
  }'
```

### Deletar automacao

```bash
curl -X DELETE 'http://localhost:3000/api/v1/accounts/1/automation_rules/{rule_id}' \
  -H 'api_access_token: TOKEN'
```

---

## Inbox WhatsApp API (Quepasa)

Canal customizado que conecta ao Quepasa para envio/recebimento de mensagens WhatsApp via QR Code.

### Criar inbox

```
POST /api/v1/accounts/{account_id}/inboxes
```

**Body:**
```json
{
  "name": "WhatsApp Vendas",
  "channel": {
    "type": "whatsapp_api",
    "phone_number": "+5511999999999"
  }
}
```

| Campo | Tipo | Obrigatorio | Descricao |
|-------|------|-------------|-----------|
| name | string | sim | Nome da inbox |
| channel.type | string | sim | Deve ser `"whatsapp_api"` |
| channel.phone_number | string | nao | Preenchido automaticamente ao conectar |

**Exemplo:**
```bash
curl -X POST 'http://localhost:3000/api/v1/accounts/1/inboxes' \
  -H 'api_access_token: TOKEN' \
  -H 'Content-Type: application/json' \
  -d '{
    "name": "WhatsApp Vendas",
    "channel": {
      "type": "whatsapp_api"
    }
  }'
```

**Resposta (trecho):**
```json
{
  "id": 5,
  "name": "WhatsApp Vendas",
  "channel_id": 3,
  "channel_type": "Channel::WhatsappApi",
  ...
}
```

### Gerar QR Code (scan)

```
GET /api/v1/accounts/{account_id}/channels/whatsapp_api/{channel_id}/scan
```

**Response:** Imagem PNG do QR Code

```bash
curl 'http://localhost:3000/api/v1/accounts/1/channels/whatsapp_api/3/scan' \
  -H 'api_access_token: TOKEN' \
  --output qrcode.png
```

### Verificar conexao

```
GET /api/v1/accounts/{account_id}/channels/whatsapp_api/{channel_id}/info
```

**Response (conectado):**
```json
{
  "verified": true,
  "connected": true,
  "wid": "5511999999999@s.whatsapp.net",
  ...
}
```

**Response (desconectado):**
```json
{
  "verified": false,
  "connected": false
}
```

### Atualizar conexao

```
POST /api/v1/accounts/{account_id}/channels/whatsapp_api/{channel_id}/update_connection
```

**Body:**
```json
{
  "connection_info": {
    "wid": "5511999999999@s.whatsapp.net",
    "token": "abc123",
    "verified": true
  }
}
```

### Desconectar

```
DELETE /api/v1/accounts/{account_id}/channels/whatsapp_api/{channel_id}/disconnect
```

### Atualizar configuracoes

```
POST /api/v1/accounts/{account_id}/channels/whatsapp_api/{channel_id}/update_settings
```

**Body:**
```json
{
  "ignore_groups": true
}
```

### Webhook de mensagens recebidas

O Quepasa envia mensagens para:

```
POST /api/v1/webhooks/whatsapp_api/{inbox_id}
```

Este endpoint e configurado automaticamente ao conectar via QR Code.

---

## Configuracao do Agent Bot

Para que o bot receba webhooks, e necessario vincular um Agent Bot ao inbox.

### Criar Agent Bot

```bash
curl -X POST 'http://localhost:3000/api/v1/accounts/1/agent_bots' \
  -H 'api_access_token: TOKEN' \
  -H 'Content-Type: application/json' \
  -d '{
    "name": "Meu Bot IA",
    "outgoing_url": "https://meu-bot.com/webhook"
  }'
```

### Vincular bot ao inbox

```bash
curl -X POST 'http://localhost:3000/api/v1/accounts/1/inboxes/{inbox_id}/set_agent_bot' \
  -H 'api_access_token: TOKEN' \
  -H 'Content-Type: application/json' \
  -d '{
    "agent_bot": 1
  }'
```

### Fluxo completo de setup

1. Criar inbox WhatsApp API
2. Conectar via QR Code (scan → info → update_connection)
3. Criar Agent Bot com outgoing_url
4. Vincular bot ao inbox
5. (Opcional) Criar automacoes de team → bot
6. Testar: enviar mensagem pelo WhatsApp → webhook chega no bot

---

## Resumo dos Endpoints Custom

| Metodo | Endpoint | Descricao |
|--------|----------|-----------|
| POST | `/conversations/{id}/toggle_bot` | Ativar/desativar bot na conversa |
| GET | `/channels/whatsapp_api/{id}/scan` | QR Code do WhatsApp |
| GET | `/channels/whatsapp_api/{id}/info` | Status da conexao |
| POST | `/channels/whatsapp_api/{id}/update_connection` | Salvar conexao |
| DELETE | `/channels/whatsapp_api/{id}/disconnect` | Desconectar WhatsApp |
| POST | `/channels/whatsapp_api/{id}/update_settings` | Config (ignore groups) |
| POST | `/automation_rules` | Criar automacao (suporta bot_enabled) |

Todos os endpoints seguem o padrao: `/api/v1/accounts/{account_id}/...`
