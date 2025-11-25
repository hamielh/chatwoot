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
    selectedAppData: {
      type: Object,
      default: () => ({}),
    },
  },
  emits: ['close'],
  setup() {
    return { v$: useVuelidate() };
  },
  validations: {
    app: {
      title: { required },
      url: { required, url },
      display_location: { required },
      position: { required, numeric, minValue: minValue(0) },
      icon: { required },
    },
  },
  data() {
    return {
      isLoading: false,
      app: {
        title: '',
        url: '',
        display_location: 'apps_menu',
        position: 0,
        icon: 'i-lucide-app-window',
        allowed_roles: [],
      },
      availableIcons: [
        {
          key: 'i-lucide-app-window',
          label: 'App Window',
          category: 'General',
        },
        {
          key: 'i-lucide-layout-dashboard',
          label: 'Dashboard',
          category: 'General',
        },
        { key: 'i-lucide-gauge', label: 'Gauge', category: 'General' },
        { key: 'i-lucide-activity', label: 'Activity', category: 'General' },
        {
          key: 'i-lucide-bar-chart',
          label: 'Bar Chart',
          category: 'Analytics',
        },
        {
          key: 'i-lucide-pie-chart',
          label: 'Pie Chart',
          category: 'Analytics',
        },
        {
          key: 'i-lucide-line-chart',
          label: 'Line Chart',
          category: 'Analytics',
        },
        {
          key: 'i-lucide-trending-up',
          label: 'Trending Up',
          category: 'Analytics',
        },
        { key: 'i-lucide-users', label: 'CRM', category: 'CRM' },
        { key: 'i-lucide-contact', label: 'Contact', category: 'CRM' },
        { key: 'i-lucide-user-check', label: 'User Check', category: 'CRM' },
        { key: 'i-lucide-user-circle', label: 'User Circle', category: 'CRM' },
        { key: 'i-lucide-trello', label: 'Kanban Board', category: 'Project' },
        {
          key: 'i-lucide-list-checks',
          label: 'Task List',
          category: 'Project',
        },
        {
          key: 'i-lucide-git-branch',
          label: 'Workflow',
          category: 'Automation',
        },
        { key: 'i-lucide-workflow', label: 'Flow', category: 'Automation' },
        { key: 'i-lucide-zap', label: 'Automation', category: 'Automation' },
        {
          key: 'i-lucide-git-pull-request',
          label: 'Pull Request',
          category: 'Development',
        },
        { key: 'i-lucide-code', label: 'Code', category: 'Development' },
        {
          key: 'i-lucide-terminal',
          label: 'Terminal',
          category: 'Development',
        },
        { key: 'i-lucide-database', label: 'Database', category: 'Data' },
        { key: 'i-lucide-table', label: 'Table', category: 'Data' },
        {
          key: 'i-lucide-file-spreadsheet',
          label: 'Spreadsheet',
          category: 'Data',
        },
        {
          key: 'i-lucide-shopping-cart',
          label: 'E-commerce',
          category: 'Business',
        },
        { key: 'i-lucide-wallet', label: 'Wallet', category: 'Business' },
        { key: 'i-lucide-receipt', label: 'Receipt', category: 'Business' },
        { key: 'i-lucide-package', label: 'Package', category: 'Business' },
        { key: 'i-lucide-rocket', label: 'Rocket', category: 'Marketing' },
        { key: 'i-lucide-megaphone', label: 'Campaign', category: 'Marketing' },
        { key: 'i-lucide-mail', label: 'Email', category: 'Communication' },
        {
          key: 'i-lucide-message-square',
          label: 'Chat',
          category: 'Communication',
        },
        { key: 'i-lucide-phone', label: 'Phone', category: 'Communication' },
        {
          key: 'i-lucide-calendar',
          label: 'Calendar',
          category: 'Productivity',
        },
        { key: 'i-lucide-clock', label: 'Time', category: 'Productivity' },
        {
          key: 'i-lucide-file-text',
          label: 'Document',
          category: 'Productivity',
        },
        { key: 'i-lucide-settings', label: 'Settings', category: 'System' },
        { key: 'i-lucide-shield', label: 'Security', category: 'System' },
        { key: 'i-lucide-bell', label: 'Notifications', category: 'System' },
      ],
      availableRoles: [
        { key: 'administrator', label: 'Administrator' },
        { key: 'agent', label: 'Agent' },
      ],
      displayLocationOptions: [
        { key: 'root', label: this.$t('SIDEBAR_APPS.FORM.LOCATION_ROOT') },
        {
          key: 'apps_menu',
          label: this.$t('SIDEBAR_APPS.FORM.LOCATION_APPS_MENU'),
        },
      ],
    };
  },
  computed: {
    header() {
      return this.$t(`SIDEBAR_APPS.${this.mode}.HEADER`);
    },
    submitButtonLabel() {
      return this.$t(`SIDEBAR_APPS.${this.mode}.FORM_SUBMIT`);
    },
  },
  mounted() {
    if (this.mode === 'UPDATE' && this.selectedAppData) {
      this.app = {
        title: this.selectedAppData.title,
        url: this.selectedAppData.url,
        display_location: this.selectedAppData.display_location,
        position: this.selectedAppData.position,
        icon: this.selectedAppData.icon || 'i-lucide-app-window',
        allowed_roles: this.selectedAppData.allowed_roles || [],
      };
    }
  },
  methods: {
    closeModal() {
      this.app = {
        title: '',
        url: '',
        display_location: 'apps_menu',
        position: 0,
        icon: 'i-lucide-app-window',
        allowed_roles: [],
      };
      this.$emit('close');
    },
    toggleRole(roleKey) {
      const index = this.app.allowed_roles.indexOf(roleKey);
      if (index > -1) {
        this.app.allowed_roles.splice(index, 1);
      } else {
        this.app.allowed_roles.push(roleKey);
      }
    },
    isRoleSelected(roleKey) {
      return this.app.allowed_roles.includes(roleKey);
    },
    async submit() {
      try {
        this.v$.$touch();
        if (this.v$.$invalid) {
          return;
        }

        const action = this.mode.toLowerCase();
        const payload = {
          title: this.app.title,
          url: this.app.url,
          display_location: this.app.display_location,
          position: parseInt(this.app.position, 10),
          icon: this.app.icon,
          allowed_roles: this.app.allowed_roles,
        };

        if (action === 'update') {
          payload.id = this.selectedAppData.id;
        }

        this.isLoading = true;
        await this.$store.dispatch(`sidebarApps/${action}`, payload);
        useAlert(this.$t(`SIDEBAR_APPS.${this.mode}.API_SUCCESS`));
        this.closeModal();
      } catch (err) {
        useAlert(this.$t(`SIDEBAR_APPS.${this.mode}.API_ERROR`));
      } finally {
        this.isLoading = false;
      }
    },
  },
};
</script>

<template>
  <woot-modal :show="show" :on-close="closeModal">
    <div class="flex flex-col h-auto overflow-auto">
      <woot-modal-header :header-title="header" />
      <form class="w-full" @submit.prevent="submit">
        <woot-input
          v-model="app.title"
          :class="{ error: v$.app.title.$error }"
          class="w-full"
          :label="$t('SIDEBAR_APPS.FORM.TITLE_LABEL')"
          :placeholder="$t('SIDEBAR_APPS.FORM.TITLE_PLACEHOLDER')"
          :error="
            v$.app.title.$error ? $t('SIDEBAR_APPS.FORM.TITLE_ERROR') : null
          "
          data-testid="app-title"
          @input="v$.app.title.$touch"
          @blur="v$.app.title.$touch"
        />
        <woot-input
          v-model="app.url"
          :class="{ error: v$.app.url.$error }"
          class="w-full"
          :label="$t('SIDEBAR_APPS.FORM.URL_LABEL')"
          :placeholder="$t('SIDEBAR_APPS.FORM.URL_PLACEHOLDER')"
          :error="v$.app.url.$error ? $t('SIDEBAR_APPS.FORM.URL_ERROR') : null"
          data-testid="app-url"
          @input="v$.app.url.$touch"
          @blur="v$.app.url.$touch"
        />

        <div class="w-full mb-4">
          <label class="block mb-2 text-sm font-medium text-n-slate-12">
            {{ $t('SIDEBAR_APPS.FORM.ICON_LABEL') }}
          </label>
          <div
            class="grid grid-cols-6 gap-2 p-3 border rounded-md border-n-border bg-n-background max-h-48 overflow-y-auto"
          >
            <button
              v-for="icon in availableIcons"
              :key="icon.key"
              type="button"
              class="flex items-center justify-center p-2 rounded-md transition-all"
              :class="[
                app.icon === icon.key
                  ? 'bg-primary-100 dark:bg-primary-900 ring-2 ring-primary-500'
                  : 'bg-n-alpha-3 hover:bg-n-alpha-4',
              ]"
              :title="`${icon.label} (${icon.category})`"
              @click="app.icon = icon.key"
            >
              <i
                class="text-xl"
                :class="[
                  icon.key,
                  app.icon === icon.key
                    ? 'text-primary-600 dark:text-primary-400'
                    : 'text-n-slate-11',
                ]"
              />
            </button>
          </div>
          <p class="mt-1 text-xs text-n-slate-11">
            {{ $t('SIDEBAR_APPS.FORM.ICON_HELP') }}
          </p>
        </div>

        <div class="w-full mb-4">
          <label class="block mb-2 text-sm font-medium text-n-slate-12">
            {{ $t('SIDEBAR_APPS.FORM.LOCATION_LABEL') }}
          </label>
          <select
            v-model="app.display_location"
            class="w-full px-3 py-2 border rounded-md border-n-border bg-n-background text-n-slate-12"
            data-testid="app-location"
          >
            <option
              v-for="option in displayLocationOptions"
              :key="option.key"
              :value="option.key"
            >
              {{ option.label }}
            </option>
          </select>
          <p class="mt-1 text-xs text-n-slate-11">
            {{ $t('SIDEBAR_APPS.FORM.LOCATION_HELP') }}
          </p>
        </div>

        <woot-input
          v-model="app.position"
          :class="{ error: v$.app.position.$error }"
          class="w-full"
          type="number"
          :label="$t('SIDEBAR_APPS.FORM.POSITION_LABEL')"
          :placeholder="$t('SIDEBAR_APPS.FORM.POSITION_PLACEHOLDER')"
          :error="
            v$.app.position.$error
              ? $t('SIDEBAR_APPS.FORM.POSITION_ERROR')
              : null
          "
          data-testid="app-position"
          @input="v$.app.position.$touch"
          @blur="v$.app.position.$touch"
        />

        <div class="w-full mb-4">
          <label class="block mb-2 text-sm font-medium text-n-slate-12">
            {{ $t('SIDEBAR_APPS.FORM.ROLES_LABEL') }}
          </label>
          <div class="flex flex-col gap-2">
            <label
              v-for="role in availableRoles"
              :key="role.key"
              class="flex items-center gap-2 cursor-pointer"
            >
              <input
                type="checkbox"
                :checked="isRoleSelected(role.key)"
                class="w-4 h-4 rounded border-n-border text-primary-600 focus:ring-primary-500"
                @change="toggleRole(role.key)"
              />
              <span class="text-sm text-n-slate-12">{{ role.label }}</span>
            </label>
          </div>
          <p class="mt-1 text-xs text-n-slate-11">
            {{ $t('SIDEBAR_APPS.FORM.ROLES_HELP') }}
          </p>
        </div>

        <div class="flex flex-row justify-end w-full gap-2 px-0 py-2">
          <NextButton
            faded
            slate
            type="reset"
            :label="$t('SIDEBAR_APPS.CREATE.FORM_CANCEL')"
            @click.prevent="closeModal"
          />
          <NextButton
            type="submit"
            :label="submitButtonLabel"
            :disabled="v$.$invalid"
            :is-loading="isLoading"
          />
        </div>
      </form>
    </div>
  </woot-modal>
</template>
