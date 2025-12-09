# 📋 INTEGRAÇÃO QUEPASA → CHATWOOT - DOCUMENTAÇÃO COMPLETA

## 🎯 CONTEXTO

Este documento contém **TODAS** as informações necessárias para implementar a integração completa entre Quepasa e Chatwoot.

**Status Atual:** FASE 1 CONCLUÍDA ✅
**Próxima Fase:** FASE 2 - Estrutura Base

---

## 📊 RESUMO DO PROGRESSO

### ✅ O QUE JÁ ESTÁ PRONTO

1. **Channel Model** - `Channel::WhatsappApi` criado
2. **Database** - Migração rodada com sucesso
3. **Menu UI** - WhatsApp API dentro do menu WhatsApp
4. **Inbox Creation** - Formulário simplificado funcionando
5. **QR Code Connection** - Geração e leitura do QR funcionando
6. **Connection Status** - Verificação persistente do status
7. **Disconnect** - Botão de desconectar funcionando
8. **Translations** - EN e PT-BR completos e corretos

### 🔧 O QUE FALTA (FASE 2 EM DIANTE)

1. **Receber Mensagens** - Webhook do Quepasa → Chatwoot
2. **Enviar Mensagens** - Chatwoot → API do Quepasa
3. **Processar Anexos** - Download e upload de mídias
4. **Status de Leitura** - Marcar como lido/entregue

---

## 🔑 INFORMAÇÕES DA API QUEPASA

### Base URL
```
https://pixel-quepasa.f7unst.easypanel.host
```

### Autenticação
- **Token**: `chatwoot-{inbox_id}` (ex: `chatwoot-4`)
- **User**: `hamielhenrique29@gmail.com` (via env var `QUEPASA_API_USER`)
- **Format**: Query params `?token=xxx&user=xxx`

---

## 📡 ENDPOINTS DA QUEPASA

### 1. ENVIAR MENSAGEM

**Endpoint:**
```
POST /v3/bot/{token}/send
```

**Headers:**
```
Content-Type: application/json
X-QUEPASA-CHATID: {recipient_phone}@s.whatsapp.net
```

**Body - Texto:**
```json
{
  "text": "Olá, como posso ajudar?"
}
```

**Body - Com Anexo:**
```json
{
  "text": "Aqui está o documento",
  "attachment": "https://url-do-arquivo.com/document.pdf"
}
```

**Exemplo cURL:**
```bash
curl -X POST 'https://pixel-quepasa.f7unst.easypanel.host/v3/bot/chatwoot-4/send' \
  -H 'Content-Type: application/json' \
  -H 'X-QUEPASA-CHATID: 5511999999999@s.whatsapp.net' \
  -d '{"text": "Olá"}'
```

---

### 2. RECEBER MENSAGEM (Webhook)

**URL Format:**
```
POST {chatwoot_url}/api/v1/webhooks/whatsapp_api/{inbox_id}
```

**Payload - Texto:**
```json
{
  "message": {
    "id": "3EB0ABC123DEF456",
    "text": "Olá, preciso de ajuda",
    "from": "5511999999999@s.whatsapp.net",
    "chat": {
      "id": "5511999999999@s.whatsapp.net",
      "phone": "5511999999999"
    },
    "timestamp": 1696615906,
    "type": "text",
    "fromMe": false
  }
}
```

**Payload - Com Mídia:**
```json
{
  "message": {
    "id": "3EB0ABC123DEF456",
    "text": "Veja esta imagem",
    "from": "5511999999999@s.whatsapp.net",
    "chat": {
      "id": "5511999999999@s.whatsapp.net",
      "phone": "5511999999999"
    },
    "timestamp": 1696615906,
    "type": "image",
    "fromMe": false,
    "attachment": {
      "url": "https://quepasa-url.com/download/MSG_ID",
      "mimetype": "image/jpeg",
      "filename": "photo.jpg"
    }
  }
}
```

**Tipos de Mensagem:**
- `text` - Texto
- `image` - Imagem
- `audio` - Áudio/Voice
- `video` - Vídeo
- `document` - Documento
- `contact` - Contato (vCard)
- `location` - Localização

---

### 3. DOWNLOAD DE MÍDIA

**Endpoint:**
```
GET /download/{message_id}?token={token}&user={user}
```

**Exemplo:**
```bash
curl "https://pixel-quepasa.f7unst.easypanel.host/download/3EB0ABC123DEF456?token=chatwoot-4&user=hamielhenrique29@gmail.com"
```

**Response:** Binary (arquivo)

---

### 4. INFORMAÇÕES DA CONEXÃO

**Endpoint:**
```
GET /info?token={token}&user={user}
```

**Response:**
```json
{
  "success": true,
  "server": {
    "token": "chatwoot-4",
    "wid": "556697177520:22@s.whatsapp.net",
    "verified": true
  }
}
```

---

### 5. CONFIGURAR WEBHOOK

**Endpoint:**
```
POST /v1/bot/{token}/webhook
```

**Body:**
```json
{
  "url": "https://meu-chatwoot.com/api/v1/webhooks/whatsapp_api/123"
}
```

---

## 🏗️ ARQUITETURA DO CHATWOOT (Investigação FASE 1)

### Padrão de Webhooks no Chatwoot:

```
Webhook Externo → Controller → Job Assíncrono → Service → Contact/Conversation/Message
```

### Exemplo: Telegram

**1. Controller** (`app/controllers/webhooks/telegram_controller.rb`)
```ruby
class Webhooks::TelegramController < ActionController::API
  def process_payload
    Webhooks::TelegramEventsJob.perform_later(params.to_unsafe_hash)
    head :ok
  end
end
```

**2. Job** (`app/jobs/webhooks/telegram_events_job.rb`)
```ruby
class Webhooks::TelegramEventsJob < ApplicationJob
  def perform(params = {})
    channel = Channel::Telegram.find_by(bot_token: params[:bot_token])
    return if channel.blank? || !channel.account.active?

    Telegram::IncomingMessageService.new(
      inbox: channel.inbox,
      params: params['telegram']
    ).perform
  end
end
```

**3. Service** (`app/services/telegram/incoming_message_service.rb`)
```ruby
class Telegram::IncomingMessageService
  def perform
    set_contact           # Cria/encontra Contact
    update_contact_avatar
    set_conversation      # Cria/encontra Conversation

    @message = @conversation.messages.build(
      content: telegram_params_message_content,
      account_id: @inbox.account_id,
      inbox_id: @inbox.id,
      message_type: :incoming,
      sender: @contact,
      source_id: telegram_params_message_id.to_s
    )

    process_message_attachments  # Downloads + ActiveStorage
    @message.save!
  end
end
```

---

## 📋 ESTRUTURA DE DADOS DO CHATWOOT

### Contact (Contato)
```ruby
ContactInboxWithContactBuilder.new(
  source_id: "5511999999999",  # Número do WhatsApp
  inbox: inbox,
  contact_attributes: {
    name: "João Silva",
    additional_attributes: {
      username: "@joao",
      language_code: "pt_BR"
    }
  }
).perform
```

### Conversation (Conversa)
```ruby
Conversation.create!(
  account_id: inbox.account_id,
  inbox_id: inbox.id,
  contact_id: contact.id,
  contact_inbox_id: contact_inbox.id,
  additional_attributes: {
    chat_id: "5511999999999@s.whatsapp.net"
  }
)
```

### Message (Mensagem)
```ruby
conversation.messages.build(
  content: "Texto da mensagem",
  account_id: inbox.account_id,
  inbox_id: inbox.id,
  message_type: :incoming,  # ou :outgoing
  sender: contact,           # nil se outgoing
  source_id: "MSG_ID_EXTERNO"
)
```

### Attachment (Anexo)
```ruby
message.attachments.new(
  account_id: message.account_id,
  file_type: :image,  # :audio, :video, :document, :location, :contact
  file: {
    io: attachment_file,
    filename: "image.jpg",
    content_type: "image/jpeg"
  }
)
```

---

## 🗺️ MAPEAMENTO QUEPASA → CHATWOOT

| Quepasa | Chatwoot |
|---------|----------|
| `message.chat.phone` | `Contact.source_id` |
| `message.text` | `Message.content` |
| `message.id` | `Message.source_id` |
| `message.from` | Extrair número, criar Contact |
| `message.type` | Detectar tipo, criar Attachment se necessário |
| `message.attachment.url` | Download → ActiveStorage |
| `message.fromMe = false` | `message_type: :incoming` |
| `message.fromMe = true` | `message_type: :outgoing` |

---

## 📝 PLANO DE AÇÃO COMPLETO

### ✅ FASE 1: INVESTIGAÇÃO (CONCLUÍDA)

- ✅ Estudar webhook do Telegram
- ✅ Estudar webhook do WhatsApp Cloud
- ✅ Entender estrutura de Conversations e Messages
- ✅ Documentar formato do webhook do Quepasa

---

### 🔨 FASE 2: ESTRUTURA BASE

**Arquivos a criar:**

#### 1. Webhook Controller
**Path:** `app/controllers/api/v1/webhooks/whatsapp_api_controller.rb`

```ruby
class Api::V1::Webhooks::WhatsappApiController < ApplicationController
  skip_before_action :verify_authenticity_token
  skip_before_action :authenticate_user!

  def create
    # Encontrar inbox pelo ID na URL
    inbox = ::Inbox.find(params[:inbox_id])
    channel = inbox.channel

    # Validar que é Channel::WhatsappApi
    return head :not_found unless channel.is_a?(Channel::WhatsappApi)

    # Validar que conta está ativa
    return head :unprocessable_entity unless channel.account.active?

    # Processar assincronamente
    Webhooks::WhatsappApiEventsJob.perform_later(
      inbox_id: inbox.id,
      params: params.to_unsafe_hash
    )

    head :ok
  end
end
```

#### 2. Events Job
**Path:** `app/jobs/webhooks/whatsapp_api_events_job.rb`

```ruby
class Webhooks::WhatsappApiEventsJob < ApplicationJob
  queue_as :default

  def perform(inbox_id:, params:)
    inbox = ::Inbox.find_by(id: inbox_id)
    return if inbox.blank?
    return unless inbox.account.active?

    # Processar mensagem
    WhatsappApi::IncomingMessageService.new(
      inbox: inbox,
      params: params
    ).perform
  end
end
```

#### 3. Incoming Message Service
**Path:** `app/services/whatsapp_api/incoming_message_service.rb`

```ruby
class WhatsappApi::IncomingMessageService
  pattr_initialize [:inbox!, :params!]

  def perform
    return unless message_params.present?

    set_contact
    set_conversation
    create_message
    process_attachments if has_attachment?
    @message.save!
  end

  private

  def message_params
    @message_params ||= params['message'] || params[:message]
  end

  def phone_number
    @phone_number ||= message_params.dig('chat', 'phone') ||
                      message_params.dig(:chat, :phone)
  end

  def set_contact
    contact_inbox = ::ContactInboxWithContactBuilder.new(
      source_id: phone_number,
      inbox: inbox,
      contact_attributes: {
        name: phone_number,  # Pode melhorar depois
        additional_attributes: {
          social_whatsapp_phone_number: phone_number
        }
      }
    ).perform

    @contact_inbox = contact_inbox
    @contact = contact_inbox.contact
  end

  def set_conversation
    @conversation = @contact_inbox.conversations
                                  .where.not(status: :resolved)
                                  .last

    return if @conversation

    @conversation = ::Conversation.create!(
      account_id: inbox.account_id,
      inbox_id: inbox.id,
      contact_id: @contact.id,
      contact_inbox_id: @contact_inbox.id,
      additional_attributes: {
        chat_id: message_params['from'] || message_params[:from]
      }
    )
  end

  def create_message
    @message = @conversation.messages.build(
      content: message_content,
      account_id: inbox.account_id,
      inbox_id: inbox.id,
      message_type: message_type,
      sender: message_sender,
      source_id: message_params['id'] || message_params[:id]
    )
  end

  def message_content
    message_params['text'] || message_params[:text] || ''
  end

  def message_type
    from_me? ? :outgoing : :incoming
  end

  def message_sender
    from_me? ? nil : @contact
  end

  def from_me?
    message_params['fromMe'] == true || message_params[:fromMe] == true
  end

  def has_attachment?
    message_params['attachment'].present? || message_params[:attachment].present?
  end

  def process_attachments
    attachment_data = message_params['attachment'] || message_params[:attachment]
    return unless attachment_data

    # Download do arquivo
    download_url = attachment_data['url'] || attachment_data[:url]
    file = Down.download(download_url)

    # Criar attachment
    @message.attachments.new(
      account_id: @message.account_id,
      file_type: detect_file_type(message_params['type'] || message_params[:type]),
      file: {
        io: file,
        filename: file.original_filename,
        content_type: file.content_type
      }
    )
  end

  def detect_file_type(type)
    case type
    when 'image' then :image
    when 'audio', 'voice' then :audio
    when 'video' then :video
    when 'document' then :file
    else :file
    end
  end
end
```

#### 4. Adicionar Rota
**Path:** `config/routes.rb`

Adicionar dentro de `namespace :api do namespace :v1 do`:

```ruby
namespace :webhooks do
  post 'whatsapp_api/:inbox_id', to: 'whatsapp_api#create'
end
```

**Rota final:**
```
POST /api/v1/webhooks/whatsapp_api/:inbox_id
```

---

### 📨 FASE 3: ENVIAR MENSAGENS

**Arquivo a criar:**

#### Send Message Service
**Path:** `app/services/whatsapp_api/send_message_service.rb`

```ruby
class WhatsappApi::SendMessageService
  pattr_initialize [:message!]

  def perform
    return unless message.outgoing?
    return if message.source_id.present? # Já foi enviado

    channel = message.inbox.channel
    return unless channel.is_a?(Channel::WhatsappApi)

    # Montar payload
    payload = {
      text: message.content
    }

    # Adicionar anexo se houver
    if message.attachments.any?
      attachment = message.attachments.first
      payload[:attachment] = attachment.file.url
    end

    # Enviar para Quepasa
    response = send_to_quepasa(channel, payload)

    # Salvar source_id da resposta
    if response.success?
      message.update(source_id: response.parsed_response['result']['id'])
    end
  end

  private

  def send_to_quepasa(channel, payload)
    base_url = ENV['QUEPASA_API_URL']
    token = channel.provider_config['token']
    recipient = message.conversation.contact_inbox.source_id

    HTTParty.post(
      "#{base_url}/v3/bot/#{token}/send",
      headers: {
        'Content-Type' => 'application/json',
        'X-QUEPASA-CHATID' => "#{recipient}@s.whatsapp.net"
      },
      body: payload.to_json,
      timeout: 15
    )
  end
end
```

#### Event Listener
**Path:** `app/listeners/whatsapp_api_events_listener.rb`

```ruby
class WhatsappApiEventsListener < BaseListener
  def message_created(event)
    message = extract_message_and_account(event)[0]
    return unless message.outgoing?
    return unless message.inbox.channel_type == 'Channel::WhatsappApi'

    WhatsappApi::SendMessageService.new(message: message).perform
  end
end
```

Registrar no `config/application.rb`:
```ruby
config.active_job.queue_adapter = :sidekiq
config.event_store.subscribe(WhatsappApiEventsListener.new, to: [MessageCreated])
```

---

## 🧪 COMO TESTAR

### 1. Receber Mensagem (Webhook)

**Request:**
```bash
curl -X POST 'http://localhost:3000/api/v1/webhooks/whatsapp_api/1' \
  -H 'Content-Type: application/json' \
  -d '{
    "message": {
      "id": "TEST123",
      "text": "Olá do Quepasa!",
      "from": "5511999999999@s.whatsapp.net",
      "chat": {
        "id": "5511999999999@s.whatsapp.net",
        "phone": "5511999999999"
      },
      "timestamp": 1696615906,
      "type": "text",
      "fromMe": false
    }
  }'
```

**Verificar:**
- ✅ Contact criado com source_id = "5511999999999"
- ✅ Conversation criada
- ✅ Message criada com content = "Olá do Quepasa!"

---

### 2. Enviar Mensagem

**Via UI Chatwoot:**
1. Abrir conversa
2. Digitar mensagem
3. Enviar

**Verificar logs:**
```ruby
# Rails console
message = Message.last
WhatsappApi::SendMessageService.new(message: message).perform
```

---

## 🌍 VARIÁVEIS DE AMBIENTE

Adicionar no `.env`:

```bash
# Quepasa API Configuration
QUEPASA_API_URL=https://pixel-quepasa.f7unst.easypanel.host
QUEPASA_API_USER=hamielhenrique29@gmail.com
```

---

## 📁 ESTRUTURA DE ARQUIVOS (Resumo)

```
app/
├── controllers/
│   └── api/v1/webhooks/
│       └── whatsapp_api_controller.rb  # ← CRIAR
├── jobs/
│   └── webhooks/
│       └── whatsapp_api_events_job.rb  # ← CRIAR
├── services/
│   └── whatsapp_api/
│       ├── incoming_message_service.rb  # ← CRIAR
│       └── send_message_service.rb      # ← CRIAR
├── listeners/
│   └── whatsapp_api_events_listener.rb  # ← CRIAR
└── models/
    └── channel/
        └── whatsapp_api.rb  # ✅ JÁ EXISTE

config/
└── routes.rb  # ← MODIFICAR (adicionar rota)
```

---

## 🚀 ORDEM DE IMPLEMENTAÇÃO

1. **Webhook Controller** → Recebe e responde 200 OK
2. **Events Job** → Processa assincronamente
3. **Incoming Message Service** → Cria Contact/Conversation/Message
4. **Rota** → Adiciona no routes.rb
5. **Send Message Service** → Envia para Quepasa
6. **Event Listener** → Ouve MessageCreated

---

## 📞 INFORMAÇÕES DE CONTATO

**Quepasa Base URL:** `https://pixel-quepasa.f7unst.easypanel.host`
**User:** `hamielhenrique29@gmail.com`
**Token Pattern:** `chatwoot-{inbox_id}`

---

**Última Atualização:** 2025-11-16
**Versão do Chatwoot:** 4.7.0
**Status:** Pronto para FASE 2 🚀
