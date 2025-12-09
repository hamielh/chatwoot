<script>
/* global axios */
import { useAlert } from 'dashboard/composables';
import Modal from 'dashboard/components/Modal.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';
import Icon from 'dashboard/components-next/icon/Icon.vue';

export default {
  components: {
    Modal,
    NextButton,
    Icon,
  },
  props: {
    inbox: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      showQRModal: false,
      isCheckingConnection: false,
      connectionCheckInterval: null,
      isConnected: false,
      phoneNumber: '',
      token: '',
      qrCodeImage: null,
      ignoreGroups: false,
      isSavingSettings: false,
    };
  },
  computed: {
    accountId() {
      return this.$route.params.accountId;
    },
    channelId() {
      return this.inbox?.channel_id;
    },
    providerConfig() {
      return this.inbox?.provider_config || {};
    },
  },
  async mounted() {
    // Busca o status atual da conexão na API do Quepasa
    await this.checkConnectionStatus();

    // Carrega a configuração de ignorar grupos
    this.ignoreGroups = this.providerConfig.ignore_groups || false;
  },
  beforeUnmount() {
    if (this.connectionCheckInterval) {
      clearInterval(this.connectionCheckInterval);
    }
  },
  methods: {
    async checkConnectionStatus() {
      try {
        const response = await axios.get(
          `/api/v1/accounts/${this.accountId}/channels/whatsapp_api/${this.channelId}/info`
        );

        if (response.data && response.data.verified) {
          // Se já está conectado, atualiza o estado local
          this.isConnected = true;
          this.phoneNumber = response.data.wid || '';
          this.token = response.data.token || '';

          // Salva no banco de dados se ainda não foi salvo
          if (
            !this.providerConfig.connected ||
            this.providerConfig.wid !== response.data.wid
          ) {
            await this.saveConnectionInfo(response.data);
          }
        } else {
          // Não está conectado
          this.isConnected = false;
          this.phoneNumber = '';
          this.token = '';
        }
      } catch (error) {
        // Se der erro na API, usa os dados salvos localmente
        this.isConnected = this.providerConfig.connected || false;
        this.phoneNumber = this.providerConfig.wid || '';
        this.token = this.providerConfig.token || '';
      }
    },

    async showQRCode() {
      this.showQRModal = true;
      await this.loadQRCode();
      this.startConnectionCheck();
    },

    async loadQRCode() {
      try {
        const response = await axios.get(
          `/api/v1/accounts/${this.accountId}/channels/whatsapp_api/${this.channelId}/scan`,
          { responseType: 'blob' }
        );

        const reader = new FileReader();
        reader.onload = () => {
          this.qrCodeImage = reader.result;
        };
        reader.readAsDataURL(response.data);
      } catch (error) {
        useAlert('Failed to load QR code');
      }
    },

    async startConnectionCheck() {
      this.isCheckingConnection = true;
      this.connectionCheckInterval = setInterval(async () => {
        try {
          const response = await axios.get(
            `/api/v1/accounts/${this.accountId}/channels/whatsapp_api/${this.channelId}/info`
          );

          // A API do Quepasa retorna os dados no formato { wid, verified, token, ... }
          if (response.data && response.data.verified) {
            await this.saveConnectionInfo(response.data);
          }
        } catch (error) {
          // Continua tentando até conectar
        }
      }, 3000);
    },

    async saveConnectionInfo(connectionInfo) {
      clearInterval(this.connectionCheckInterval);

      try {
        await axios.post(
          `/api/v1/accounts/${this.accountId}/channels/whatsapp_api/${this.channelId}/update_connection`,
          { connection_info: connectionInfo }
        );

        this.isConnected = true;
        this.phoneNumber = connectionInfo.wid;
        this.token = connectionInfo.token;
        useAlert(this.$t('INBOX_MGMT.ADD.WHATSAPP_API.CONNECTION_SUCCESS'));
        this.closeQRModal();

        // Recarrega os dados da inbox
        await this.$store.dispatch('inboxes/get');
      } catch (error) {
        useAlert(this.$t('INBOX_MGMT.ADD.WHATSAPP_API.CONNECTION_ERROR'));
      }
    },

    async disconnectWhatsApp() {
      try {
        await axios.delete(
          `/api/v1/accounts/${this.accountId}/channels/whatsapp_api/${this.channelId}/disconnect`
        );

        this.isConnected = false;
        this.phoneNumber = '';
        this.token = '';
        useAlert(
          this.$t('INBOX_MGMT.ADD.WHATSAPP_API_CONNECTION.DISCONNECT_SUCCESS')
        );

        // Recarrega os dados da inbox
        await this.$store.dispatch('inboxes/get');
      } catch (error) {
        useAlert(
          this.$t('INBOX_MGMT.ADD.WHATSAPP_API_CONNECTION.DISCONNECT_ERROR')
        );
      }
    },

    closeQRModal() {
      this.showQRModal = false;
      this.isCheckingConnection = false;
      if (this.connectionCheckInterval) {
        clearInterval(this.connectionCheckInterval);
      }
    },

    async saveIgnoreGroupsSetting() {
      this.isSavingSettings = true;

      try {
        await axios.post(
          `/api/v1/accounts/${this.accountId}/channels/whatsapp_api/${this.channelId}/update_settings`,
          { ignore_groups: this.ignoreGroups }
        );

        useAlert(
          this.$t('INBOX_MGMT.ADD.WHATSAPP_API_CONNECTION.SETTINGS_SAVED')
        );

        // Recarrega os dados da inbox
        await this.$store.dispatch('inboxes/get');
      } catch (error) {
        useAlert(
          this.$t('INBOX_MGMT.ADD.WHATSAPP_API_CONNECTION.SETTINGS_ERROR')
        );
      } finally {
        this.isSavingSettings = false;
      }
    },
  },
};
</script>

<template>
  <div class="mx-8">
    <div class="ml-0 mr-0 py-8 w-full border-b border-solid border-n-weak/60">
      <div class="grid grid-cols-1 lg:grid-cols-8 gap-6">
        <!-- Left Side: Title + Description + Info -->
        <div class="col-span-2">
          <p class="text-base text-n-brand mb-0 font-medium">
            {{ $t('INBOX_MGMT.ADD.WHATSAPP_API_CONNECTION.TITLE') }}
          </p>
          <p
            class="text-sm mb-2 text-n-slate-11 leading-5 tracking-normal mt-2"
          >
            {{
              $t('INBOX_MGMT.ADD.WHATSAPP_API_CONNECTION.CONNECT_DESCRIPTION')
            }}
          </p>

          <!-- Connection Info (when connected) -->
          <div v-if="isConnected" class="mt-6">
            <div class="text-sm text-n-slate-11 mb-1">
              <span class="font-medium"
                >{{ $t('INBOX_MGMT.ADD.WHATSAPP_API_CONNECTION.TOKEN_LABEL')
                }}{{ $t('INBOX_MGMT.ADD.GENERAL.COLON') }}</span
              >
              <code class="ml-2 text-n-slate-12 font-mono">{{ token }}</code>
            </div>

            <div class="text-sm text-n-slate-11 mb-1">
              <span class="font-medium"
                >{{ $t('INBOX_MGMT.ADD.WHATSAPP_API_CONNECTION.WID_LABEL')
                }}{{ $t('INBOX_MGMT.ADD.GENERAL.COLON') }}</span
              >
              <code class="ml-2 text-n-slate-12 font-mono">{{
                phoneNumber
              }}</code>
            </div>

            <!-- Disconnect Button -->
            <div class="text-sm">
              <button
                class="text-red-600 hover:text-red-700 font-medium"
                @click="disconnectWhatsApp"
              >
                {{
                  $t('INBOX_MGMT.ADD.WHATSAPP_API_CONNECTION.DISCONNECT_BUTTON')
                }}
              </button>
            </div>
          </div>
        </div>

        <!-- Right Side: Connect Button (only when NOT connected) -->
        <div class="col-span-6 xl:col-span-5">
          <NextButton
            v-if="!isConnected"
            solid
            blue
            :label="$t('INBOX_MGMT.ADD.WHATSAPP_API_CONNECTION.CONNECT_BUTTON')"
            @click="showQRCode"
          />
        </div>
      </div>
    </div>

    <!-- Settings Section -->
    <div class="ml-0 mr-0 py-8 w-full border-b border-solid border-n-weak/60">
      <div class="grid grid-cols-1 lg:grid-cols-8 gap-6">
        <!-- Left Side: Title + Description -->
        <div class="col-span-2">
          <p class="text-base text-n-brand mb-0 font-medium">
            {{ $t('INBOX_MGMT.ADD.WHATSAPP_API_CONNECTION.SETTINGS_TITLE') }}
          </p>
          <p
            class="text-sm mb-2 text-n-slate-11 leading-5 tracking-normal mt-2"
          >
            {{
              $t('INBOX_MGMT.ADD.WHATSAPP_API_CONNECTION.SETTINGS_DESCRIPTION')
            }}
          </p>
        </div>

        <!-- Right Side: Settings -->
        <div class="col-span-6 xl:col-span-5">
          <label class="pb-4 block">
            {{
              $t('INBOX_MGMT.ADD.WHATSAPP_API_CONNECTION.IGNORE_GROUPS_LABEL')
            }}
            <select
              v-model="ignoreGroups"
              class="mt-2"
              @change="saveIgnoreGroupsSetting"
            >
              <option :value="true">
                {{
                  $t(
                    'INBOX_MGMT.ADD.WHATSAPP_API_CONNECTION.IGNORE_GROUPS_ENABLED'
                  )
                }}
              </option>
              <option :value="false">
                {{
                  $t(
                    'INBOX_MGMT.ADD.WHATSAPP_API_CONNECTION.IGNORE_GROUPS_DISABLED'
                  )
                }}
              </option>
            </select>
            <p class="pb-1 text-sm not-italic text-n-slate-11 mt-1">
              {{
                $t(
                  'INBOX_MGMT.ADD.WHATSAPP_API_CONNECTION.IGNORE_GROUPS_HELP_TEXT'
                )
              }}
            </p>
          </label>
        </div>
      </div>
    </div>

    <Modal v-model:show="showQRModal" :on-close="closeQRModal">
      <div class="flex flex-col items-center p-6">
        <h3 class="mb-4 text-lg font-medium">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP_API.QR_CODE.TITLE') }}
        </h3>
        <p class="mb-6 text-sm text-n-slate-11 text-center">
          {{ $t('INBOX_MGMT.ADD.WHATSAPP_API.QR_CODE.DESCRIPTION') }}
        </p>

        <div class="mb-6 p-4 bg-white rounded-lg">
          <img
            v-if="qrCodeImage"
            :src="qrCodeImage"
            alt="QR Code"
            class="w-64 h-64"
          />
          <div v-else class="w-64 h-64 flex items-center justify-center">
            <span class="text-sm text-n-slate-11">{{
              $t('INBOX_MGMT.ADD.WHATSAPP_API.QR_CODE.LOADING')
            }}</span>
          </div>
        </div>

        <div
          v-if="isCheckingConnection"
          class="flex items-center gap-2 text-sm text-n-slate-11"
        >
          <Icon icon="i-teenyicons-circle-solid" class="animate-pulse" />
          {{ $t('INBOX_MGMT.ADD.WHATSAPP_API.QR_CODE.WAITING') }}
        </div>
      </div>
    </Modal>
  </div>
</template>
