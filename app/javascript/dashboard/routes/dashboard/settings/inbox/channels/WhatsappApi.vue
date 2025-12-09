<script>
import { mapGetters } from 'vuex';
import { useVuelidate } from '@vuelidate/core';
import { useAlert } from 'dashboard/composables';
import { required } from '@vuelidate/validators';
import router from '../../../../index';
import NextButton from 'dashboard/components-next/button/Button.vue';

export default {
  components: {
    NextButton,
  },
  setup() {
    return { v$: useVuelidate() };
  },
  data() {
    return {
      channelName: '',
    };
  },
  computed: {
    ...mapGetters({
      uiFlags: 'inboxes/getUIFlags',
    }),
  },
  validations: {
    channelName: { required },
  },
  methods: {
    async createChannel() {
      this.v$.$touch();
      if (this.v$.$invalid) {
        return;
      }

      try {
        const whatsappApiChannel = await this.$store.dispatch(
          'inboxes/createChannel',
          {
            name: this.channelName?.trim(),
            channel: {
              type: 'whatsapp_api',
              phone_number: '',
            },
          }
        );

        router.replace({
          name: 'settings_inboxes_add_agents',
          params: {
            page: 'new',
            inbox_id: whatsappApiChannel.id,
          },
        });
      } catch (error) {
        useAlert(this.$t('INBOX_MGMT.ADD.WHATSAPP_API.API.ERROR_MESSAGE'));
      }
    },
  },
};
</script>

<template>
  <form class="flex flex-wrap flex-col mx-0" @submit.prevent="createChannel()">
    <div class="flex-shrink-0 flex-grow-0">
      <label :class="{ error: v$.channelName.$error }">
        {{ $t('INBOX_MGMT.ADD.WHATSAPP_API.CHANNEL_NAME.LABEL') }}
        <input
          v-model="channelName"
          type="text"
          :placeholder="
            $t('INBOX_MGMT.ADD.WHATSAPP_API.CHANNEL_NAME.PLACEHOLDER')
          "
          @blur="v$.channelName.$touch"
        />
        <span v-if="v$.channelName.$error" class="message">{{
          $t('INBOX_MGMT.ADD.WHATSAPP_API.CHANNEL_NAME.ERROR')
        }}</span>
      </label>
    </div>

    <div class="w-full mt-4">
      <NextButton
        :is-loading="uiFlags.isCreating"
        type="submit"
        solid
        blue
        :label="$t('INBOX_MGMT.ADD.WHATSAPP_API.SUBMIT_BUTTON')"
      />
    </div>
  </form>
</template>
