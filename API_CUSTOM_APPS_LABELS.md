# API - Custom Apps & Labels

Documentação simples das APIs de Custom Apps e Labels (Tags) do Chatwoot.

---

## Custom Apps (Sidebar Apps)

### Listar todos os apps
```bash
curl -X GET 'http://localhost:3000/api/v1/accounts/{account_id}/sidebar_apps' \
  -H 'api_access_token: SEU_TOKEN'
```

### Ver um app específico
```bash
curl -X GET 'http://localhost:3000/api/v1/accounts/{account_id}/sidebar_apps/{id}' \
  -H 'api_access_token: SEU_TOKEN'
```

### Criar novo app
```bash
curl -X POST 'http://localhost:3000/api/v1/accounts/{account_id}/sidebar_apps' \
  -H 'Content-Type: application/json' \
  -H 'api_access_token: SEU_TOKEN' \
  -d '{
    "sidebar_app": {
      "title": "Meu CRM",
      "url": "https://meu-crm.com",
      "display_location": "root",
      "position": 0,
      "icon": "i-lucide-users",
      "allowed_roles": ["administrator", "agent"]
    }
  }'
```

**Parâmetros:**
- `title` (obrigatório): Nome do app
- `url` (obrigatório): URL do app
- `display_location`: `"root"` (sidebar principal) ou `"apps_menu"` (submenu Apps)
- `position`: Ordem de exibição (número)
- `icon`: Ícone Lucide (ex: `"i-lucide-users"`, `"i-lucide-trello"`)
- `allowed_roles`: Array com roles (`["administrator", "agent"]`) ou vazio (`[]`) para todos

### Atualizar app
```bash
curl -X PATCH 'http://localhost:3000/api/v1/accounts/{account_id}/sidebar_apps/{id}' \
  -H 'Content-Type: application/json' \
  -H 'api_access_token: SEU_TOKEN' \
  -d '{
    "sidebar_app": {
      "title": "Novo Nome",
      "position": 1
    }
  }'
```

### Deletar app
```bash
curl -X DELETE 'http://localhost:3000/api/v1/accounts/{account_id}/sidebar_apps/{id}' \
  -H 'api_access_token: SEU_TOKEN'
```

---

## Labels (Tags)

### Listar todas as tags
```bash
curl -X GET 'http://localhost:3000/api/v1/accounts/{account_id}/labels' \
  -H 'api_access_token: SEU_TOKEN'
```

### Ver uma tag específica
```bash
curl -X GET 'http://localhost:3000/api/v1/accounts/{account_id}/labels/{id}' \
  -H 'api_access_token: SEU_TOKEN'
```

### Criar nova tag
```bash
curl -X POST 'http://localhost:3000/api/v1/accounts/{account_id}/labels' \
  -H 'Content-Type: application/json' \
  -H 'api_access_token: SEU_TOKEN' \
  -d '{
    "label": {
      "title": "Urgente",
      "description": "Casos que precisam de atenção imediata",
      "color": "#FF0000",
      "show_on_sidebar": true
    }
  }'
```

**Parâmetros:**
- `title` (obrigatório): Nome da tag
- `description`: Descrição da tag
- `color`: Cor em hexadecimal (ex: `"#FF0000"`)
- `show_on_sidebar`: `true` ou `false` (se aparece na sidebar)

### Atualizar tag
```bash
curl -X PATCH 'http://localhost:3000/api/v1/accounts/{account_id}/labels/{id}' \
  -H 'Content-Type: application/json' \
  -H 'api_access_token: SEU_TOKEN' \
  -d '{
    "label": {
      "title": "Novo Nome",
      "color": "#00FF00"
    }
  }'
```

### Deletar tag
```bash
curl -X DELETE 'http://localhost:3000/api/v1/accounts/{account_id}/labels/{id}' \
  -H 'api_access_token: SEU_TOKEN'
```

---

## Inboxes WhatsApp API (Quepasa)

### Listar todas as inboxes
```bash
curl -X GET 'http://localhost:3000/api/v1/accounts/{account_id}/inboxes' \
  -H 'api_access_token: SEU_TOKEN'
```

### Ver uma inbox específica
```bash
curl -X GET 'http://localhost:3000/api/v1/accounts/{account_id}/inboxes/{id}' \
  -H 'api_access_token: SEU_TOKEN'
```

### Criar inbox WhatsApp API (Quepasa)
```bash
curl -X POST 'http://localhost:3000/api/v1/accounts/{account_id}/inboxes' \
  -H 'Content-Type: application/json' \
  -H 'api_access_token: SEU_TOKEN' \
  -d '{
    "name": "WhatsApp Suporte",
    "channel": {
      "type": "whatsapp_api",
      "phone_number": "5511999999999",
      "provider_config": {
        "token": "seu-token-quepasa",
        "ignore_groups": false
      }
    }
  }'
```

**Parâmetros:**
- `name` (obrigatório): Nome da inbox
- `channel.type` (obrigatório): Use `"whatsapp_api"` para Quepasa
- `channel.phone_number`: Número do WhatsApp (opcional)
- `channel.provider_config.token`: Token do Quepasa (opcional, será gerado automaticamente se não fornecido)
- `channel.provider_config.ignore_groups`: `true` para ignorar mensagens de grupos, `false` para aceitar (padrão: false)

### Atualizar inbox
```bash
curl -X PATCH 'http://localhost:3000/api/v1/accounts/{account_id}/inboxes/{id}' \
  -H 'Content-Type: application/json' \
  -H 'api_access_token: SEU_TOKEN' \
  -d '{
    "name": "Novo Nome da Inbox",
    "greeting_enabled": true,
    "greeting_message": "Olá! Como podemos ajudar?",
    "channel": {
      "phone_number": "5511988888888",
      "provider_config": {
        "ignore_groups": true
      }
    }
  }'
```

**Parâmetros de configuração da inbox:**
- `name`: Nome da inbox
- `greeting_enabled`: Ativar mensagem de saudação (`true`/`false`)
- `greeting_message`: Texto da mensagem de saudação
- `enable_auto_assignment`: Atribuição automática de conversas (`true`/`false`)
- `csat_survey_enabled`: Pesquisa de satisfação (`true`/`false`)
- `allow_messages_after_resolved`: Permitir mensagens após resolver (`true`/`false`)

### Deletar inbox
```bash
curl -X DELETE 'http://localhost:3000/api/v1/accounts/{account_id}/inboxes/{id}' \
  -H 'api_access_token: SEU_TOKEN'
```

### Endpoints específicos do WhatsApp API (Quepasa)

#### Obter QR Code para conexão
```bash
curl -X GET 'http://localhost:3000/api/v1/accounts/{account_id}/channels/whatsapp_api/{channel_id}/scan' \
  -H 'api_access_token: SEU_TOKEN' \
  --output qrcode.png
```

#### Obter informações de conexão
```bash
curl -X GET 'http://localhost:3000/api/v1/accounts/{account_id}/channels/whatsapp_api/{channel_id}/info' \
  -H 'api_access_token: SEU_TOKEN'
```

#### Desconectar WhatsApp
```bash
curl -X DELETE 'http://localhost:3000/api/v1/accounts/{account_id}/channels/whatsapp_api/{channel_id}/info' \
  -H 'api_access_token: SEU_TOKEN'
```

#### Atualizar configurações (ignorar grupos)
```bash
curl -X PATCH 'http://localhost:3000/api/v1/accounts/{account_id}/channels/whatsapp_api/{channel_id}/update_settings' \
  -H 'Content-Type: application/json' \
  -H 'api_access_token: SEU_TOKEN' \
  -d '{
    "ignore_groups": true
  }'
```

---

## Notas

- Substitua `{account_id}` pelo ID da sua conta
- Substitua `{id}` ou `{channel_id}` pelo ID da inbox/canal
- Substitua `SEU_TOKEN` pelo seu token de API (Settings > Applications)
- Para produção, troque `http://localhost:3000` pela URL do seu servidor
- Configure as variáveis de ambiente `QUEPASA_API_URL` e `QUEPASA_API_USER` no Chatwoot
