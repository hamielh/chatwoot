<script>
import { useVuelidate } from '@vuelidate/core';
import { required, url, numeric, minValue } from '@vuelidate/validators';
import { useAlert } from 'dashboard/composables';

import NextButton from 'dashboard/components-next/button/Button.vue';

export default {
  components: {
    NextButton,
  },
  props: {
    show: {
      type: Boolean,
      default: false,
    },
    mode: {
      type: String,
      default: 'create',
    },
    selectedAgent: {
      type: Object,
      default: () => ({}),
    },
  },
  emits: ['close'],
  setup() {
    return { v$: useVuelidate() };
  },
  data() {
    return {
      agent: {
        title: '',
        webhook_url: '',
        description: '',
        position: 0,
        icon: 'i-lucide-bot',
        enabled: true,
        allowed_roles: [],
      },
      availableIcons: [
        { key: 'i-lucide-bot', label: 'Bot', category: 'AI' },
        { key: 'i-lucide-sparkles', label: 'Sparkles', category: 'AI' },
        { key: 'i-lucide-brain', label: 'Brain', category: 'AI' },
        { key: 'i-lucide-message-square', label: 'Chat', category: 'Communication' },
        { key: 'i-lucide-cpu', label: 'CPU', category: 'Tech' },
        { key: 'i-lucide-zap', label: 'Lightning', category: 'Speed' },
        { key: 'i-lucide-rocket', label: 'Rocket', category: 'Marketing' },
        { key: 'i-lucide-users', label: 'Users', category: 'CRM' },
        { key: 'i-lucide-activity', label: 'Activity', category: 'Analytics' },
        { key: 'i-lucide-settings', label: 'Settings', category: 'System' },
      ],
      availableRoles: [
        { key: 'administrator', label: 'Administrator' },
        { key: 'agent', label: 'Agent' },
      ],
    };
  },
  computed: {
    header() {
      return this.$t(`CHAT_AGENTS.${this.mode}.HEADER`);
    },
    submitButtonLabel() {
      return this.$t(`CHAT_AGENTS.${this.mode}.FORM_SUBMIT`);
    },
  },
  mounted() {
    if (this.mode === 'update' && this.selectedAgent) {
      this.agent = {
        title: this.selectedAgent.title,
        webhook_url: this.selectedAgent.webhook_url,
        description: this.selectedAgent.description || '',
        position: this.selectedAgent.position,
        icon: this.selectedAgent.icon || 'i-lucide-bot',
        enabled: this.selectedAgent.enabled,
        allowed_roles: this.selectedAgent.allowed_roles || [],
      };
    }
  },
  methods: {
    closeModal() {
      this.agent = {
        title: '',
        webhook_url: '',
        description: '',
        position: 0,
        icon: 'i-lucide-bot',
        enabled: true,
        allowed_roles: [],
      };
      this.$emit('close');
    },
    toggleRole(roleKey) {
      const index = this.agent.allowed_roles.indexOf(roleKey);
      if (index > -1) {
        this.agent.allowed_roles.splice(index, 1);
      } else {
        this.agent.allowed_roles.push(roleKey);
      }
    },
    isRoleSelected(roleKey) {
      return this.agent.allowed_roles.includes(roleKey);
    },
    async submitForm() {
      this.v$.$touch();
      if (this.v$.$invalid) return;

      try {
        if (this.mode === 'create') {
          await this.$store.dispatch('chatAgents/create', { chat_agent: this.agent });
          useAlert(this.$t(`CHAT_AGENTS.${this.mode}.API_SUCCESS`));
        } else {
          await this.$store.dispatch('chatAgents/update', { id: this.selectedAgent.id, chat_agent: this.agent });
          useAlert(this.$t(`CHAT_AGENTS.${this.mode}.API_SUCCESS`));
        }
        this.closeModal();
      } catch (error) {
        useAlert(this.$t(`CHAT_AGENTS.${this.mode}.API_ERROR`));
      }
    },
  },
  validations() {
    return {
      agent: {
        title: { required },
        webhook_url: { required, url },
        position: { required, numeric, minValue: minValue(0) },
      },
    };
  },
};
</script>

<template>
  <div
    v-if="show"
    class="fixed inset-0 z-50 flex items-center justify-center bg-black/50"
    @click.self="closeModal"
  >
    <div class="bg-n-background rounded-lg shadow-xl w-full max-w-2xl max-h-[90vh] overflow-hidden flex flex-col">
      <!-- Header -->
      <div class="flex items-center justify-between p-6 border-b border-n-border">
        <h2 class="text-xl font-semibold text-n-slate-12">
          {{ header }}
        </h2>
        <NextButton
          icon="i-lucide-x"
          xs
          slate
          faded
          @click="closeModal"
        />
      </div>

      <!-- Body -->
      <div class="flex-1 overflow-y-auto p-6 space-y-4">
        <!-- Title -->
        <div class="w-full">
          <label class="block mb-2 text-sm font-medium text-n-slate-12">
            {{ $t('CHAT_AGENTS.FORM.TITLE_LABEL') }}
            <span class="text-ruby-600">*</span>
          </label>
          <input
            v-model="agent.title"
            type="text"
            class="w-full px-3 py-2 border rounded-md bg-n-background border-n-border text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-primary-500"
            :placeholder="$t('CHAT_AGENTS.FORM.TITLE_PLACEHOLDER')"
            @input="v$.agent.title.$touch"
            @blur="v$.agent.title.$touch"
          />
          <p v-if="v$.agent.title.$error" class="mt-1 text-xs text-ruby-600">
            {{ $t('CHAT_AGENTS.FORM.TITLE_ERROR') }}
          </p>
        </div>

        <!-- Webhook URL -->
        <div class="w-full">
          <label class="block mb-2 text-sm font-medium text-n-slate-12">
            {{ $t('CHAT_AGENTS.FORM.WEBHOOK_URL_LABEL') }}
            <span class="text-ruby-600">*</span>
          </label>
          <input
            v-model="agent.webhook_url"
            type="url"
            class="w-full px-3 py-2 border rounded-md bg-n-background border-n-border text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-primary-500 font-mono text-sm"
            :placeholder="$t('CHAT_AGENTS.FORM.WEBHOOK_URL_PLACEHOLDER')"
            @input="v$.agent.webhook_url.$touch"
            @blur="v$.agent.webhook_url.$touch"
          />
          <p v-if="v$.agent.webhook_url.$error" class="mt-1 text-xs text-ruby-600">
            {{ $t('CHAT_AGENTS.FORM.WEBHOOK_URL_ERROR') }}
          </p>
          <p class="mt-1 text-xs text-n-slate-11">
            {{ $t('CHAT_AGENTS.FORM.WEBHOOK_URL_HELP') }}
          </p>
        </div>

        <!-- Description -->
        <div class="w-full">
          <label class="block mb-2 text-sm font-medium text-n-slate-12">
            {{ $t('CHAT_AGENTS.FORM.DESCRIPTION_LABEL') }}
          </label>
          <textarea
            v-model="agent.description"
            rows="3"
            class="w-full px-3 py-2 border rounded-md bg-n-background border-n-border text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-primary-500"
            :placeholder="$t('CHAT_AGENTS.FORM.DESCRIPTION_PLACEHOLDER')"
          />
        </div>

        <!-- Icon Selector -->
        <div class="w-full">
          <label class="block mb-2 text-sm font-medium text-n-slate-12">
            {{ $t('CHAT_AGENTS.FORM.ICON_LABEL') }}
          </label>
          <div class="grid grid-cols-5 gap-2 p-3 border rounded-md border-n-border bg-n-background">
            <button
              v-for="icon in availableIcons"
              :key="icon.key"
              type="button"
              class="flex items-center justify-center p-3 rounded-md transition-all"
              :class="[
                agent.icon === icon.key
                  ? 'bg-primary-100 dark:bg-primary-900 ring-2 ring-primary-500'
                  : 'bg-n-alpha-3 hover:bg-n-alpha-4',
              ]"
              :title="`${icon.label} (${icon.category})`"
              @click="agent.icon = icon.key"
            >
              <span
                class="text-2xl"
                :class="[
                  icon.key,
                  agent.icon === icon.key
                    ? 'text-primary-600 dark:text-primary-400'
                    : 'text-n-slate-11',
                ]"
              />
            </button>
          </div>
        </div>

        <!-- Enabled Toggle -->
        <div class="w-full flex items-center justify-between p-4 border rounded-md border-n-border">
          <div>
            <label class="text-sm font-medium text-n-slate-12">
              {{ $t('CHAT_AGENTS.FORM.ENABLED_LABEL') }}
            </label>
            <p class="text-xs text-n-slate-11 mt-1">
              {{ $t('CHAT_AGENTS.FORM.ENABLED_HELP') }}
            </p>
          </div>
          <label class="relative inline-flex items-center cursor-pointer">
            <input
              v-model="agent.enabled"
              type="checkbox"
              class="sr-only peer"
            />
            <div
              class="w-11 h-6 bg-n-alpha-4 peer-focus:outline-none peer-focus:ring-2 peer-focus:ring-primary-500 rounded-full peer peer-checked:after:translate-x-full peer-checked:after:border-white after:content-[''] after:absolute after:top-[2px] after:left-[2px] after:bg-white after:border-gray-300 after:border after:rounded-full after:h-5 after:w-5 after:transition-all peer-checked:bg-primary-600"
            />
          </label>
        </div>

        <!-- Position -->
        <div class="w-full">
          <label class="block mb-2 text-sm font-medium text-n-slate-12">
            {{ $t('CHAT_AGENTS.FORM.POSITION_LABEL') }}
          </label>
          <input
            v-model.number="agent.position"
            type="number"
            min="0"
            class="w-full px-3 py-2 border rounded-md bg-n-background border-n-border text-n-slate-12 focus:outline-none focus:ring-2 focus:ring-primary-500"
            @input="v$.agent.position.$touch"
            @blur="v$.agent.position.$touch"
          />
          <p class="mt-1 text-xs text-n-slate-11">
            {{ $t('CHAT_AGENTS.FORM.POSITION_HELP') }}
          </p>
        </div>

        <!-- Roles -->
        <div class="w-full">
          <label class="block mb-2 text-sm font-medium text-n-slate-12">
            {{ $t('CHAT_AGENTS.FORM.ROLES_LABEL') }}
          </label>
          <div class="space-y-2">
            <label
              v-for="role in availableRoles"
              :key="role.key"
              class="flex items-center p-3 border rounded-md cursor-pointer transition-colors"
              :class="
                isRoleSelected(role.key)
                  ? 'border-primary-500 bg-primary-50 dark:bg-primary-900/10'
                  : 'border-n-border hover:bg-n-alpha-2'
              "
            >
              <input
                type="checkbox"
                :checked="isRoleSelected(role.key)"
                class="mr-3 rounded border-n-border text-primary-600 focus:ring-primary-500"
                @change="toggleRole(role.key)"
              />
              <span class="text-sm text-n-slate-12">{{ role.label }}</span>
            </label>
          </div>
          <p class="mt-2 text-xs text-n-slate-11">
            {{ $t('CHAT_AGENTS.FORM.ROLES_HELP') }}
          </p>
        </div>
      </div>

      <!-- Footer -->
      <div class="flex items-center justify-end gap-2 p-6 border-t border-n-border">
        <NextButton
          slate
          @click="closeModal"
        >
          {{ $t('CHAT_AGENTS.FORM.CANCEL') }}
        </NextButton>
        <NextButton
          @click="submitForm"
        >
          {{ submitButtonLabel }}
        </NextButton>
      </div>
    </div>
  </div>
</template>
