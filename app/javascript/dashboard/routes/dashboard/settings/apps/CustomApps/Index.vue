<script>
import { mapGetters } from 'vuex';
import { useAlert } from 'dashboard/composables';
import CustomAppModal from './CustomAppModal.vue';
import CustomAppsRow from './CustomAppsRow.vue';
import BaseSettingsHeader from '../../components/BaseSettingsHeader.vue';
import NextButton from 'dashboard/components-next/button/Button.vue';

export default {
  components: {
    BaseSettingsHeader,
    CustomAppModal,
    CustomAppsRow,
    NextButton,
  },
  data() {
    return {
      loading: {},
      showCustomAppPopup: false,
      showDeleteConfirmationPopup: false,
      selectedApp: {},
      mode: 'CREATE',
    };
  },
  computed: {
    ...mapGetters({
      records: 'sidebarApps/getRecords',
      uiFlags: 'sidebarApps/getUIFlags',
    }),
    tableHeaders() {
      return [
        this.$t('SIDEBAR_APPS.LIST.TABLE_HEADER.NAME'),
        this.$t('SIDEBAR_APPS.LIST.TABLE_HEADER.URL'),
        this.$t('SIDEBAR_APPS.LIST.TABLE_HEADER.LOCATION'),
      ];
    },
  },
  mounted() {
    this.$store.dispatch('sidebarApps/get');
  },
  methods: {
    toggleCustomAppPopup() {
      this.showCustomAppPopup = !this.showCustomAppPopup;
      this.selectedApp = {};
    },
    openDeletePopup(response) {
      this.showDeleteConfirmationPopup = true;
      this.selectedApp = response;
    },
    openCreatePopup() {
      this.mode = 'CREATE';
      this.selectedApp = {};
      this.showCustomAppPopup = true;
    },
    closeDeletePopup() {
      this.showDeleteConfirmationPopup = false;
    },
    editApp(app) {
      this.loading[app.id] = true;
      this.mode = 'UPDATE';
      this.selectedApp = app;
      this.showCustomAppPopup = true;
    },
    confirmDeletion() {
      this.loading[this.selectedApp.id] = true;
      this.closeDeletePopup();
      this.deleteApp(this.selectedApp.id);
    },
    async deleteApp(id) {
      try {
        await this.$store.dispatch('sidebarApps/delete', id);
        useAlert(this.$t('SIDEBAR_APPS.DELETE.API_SUCCESS'));
      } catch (error) {
        useAlert(this.$t('SIDEBAR_APPS.DELETE.API_ERROR'));
      }
    },
  },
};
</script>

<template>
  <div class="flex flex-col flex-1 gap-8 overflow-auto">
    <BaseSettingsHeader
      :title="$t('SIDEBAR_APPS.TITLE')"
      :description="$t('SIDEBAR_APPS.DESCRIPTION')"
      :link-text="$t('SIDEBAR_APPS.LEARN_MORE')"
      feature-name="sidebar_apps"
      :back-button-label="$t('SETTINGS_APPS.HEADER')"
    >
      <template #actions>
        <NextButton
          icon="i-lucide-circle-plus"
          :label="$t('SIDEBAR_APPS.HEADER_BTN_TXT')"
          @click="openCreatePopup"
        />
      </template>
    </BaseSettingsHeader>
    <div class="w-full overflow-x-auto text-n-slate-11">
      <p
        v-if="!uiFlags.isFetching && !records.length"
        class="flex flex-col items-center justify-center h-full"
      >
        {{ $t('SIDEBAR_APPS.LIST.404') }}
      </p>
      <woot-loading-state
        v-if="uiFlags.isFetching"
        :message="$t('SIDEBAR_APPS.LIST.LOADING')"
      />
      <table
        v-if="!uiFlags.isFetching && records.length"
        class="min-w-full divide-y divide-n-weak"
      >
        <thead>
          <th
            v-for="thHeader in tableHeaders"
            :key="thHeader"
            class="py-4 ltr:pr-4 rtl:pl-4 font-semibold text-left text-n-slate-11"
          >
            {{ thHeader }}
          </th>
        </thead>
        <tbody class="divide-y divide-n-weak">
          <CustomAppsRow
            v-for="(customAppItem, index) in records"
            :key="customAppItem.id"
            :index="index"
            :app="customAppItem"
            @edit="editApp"
            @delete="openDeletePopup"
          />
        </tbody>
      </table>
    </div>

    <CustomAppModal
      v-if="showCustomAppPopup"
      :show="showCustomAppPopup"
      :mode="mode"
      :selected-app-data="selectedApp"
      @close="toggleCustomAppPopup"
    />

    <woot-delete-modal
      v-model:show="showDeleteConfirmationPopup"
      :on-close="closeDeletePopup"
      :on-confirm="confirmDeletion"
      :title="$t('SIDEBAR_APPS.DELETE.TITLE')"
      :message="
        $t('SIDEBAR_APPS.DELETE.MESSAGE', {
          appName: selectedApp.title,
        })
      "
      :confirm-text="$t('SIDEBAR_APPS.DELETE.CONFIRM_YES')"
      :reject-text="$t('SIDEBAR_APPS.DELETE.CONFIRM_NO')"
    />
  </div>
</template>
