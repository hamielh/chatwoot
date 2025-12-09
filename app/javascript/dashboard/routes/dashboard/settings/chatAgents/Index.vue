<script setup>
import { ref, computed, onMounted } from 'vue';
import { useStore } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import Button from 'dashboard/components-next/button/Button.vue';
import ChatAgentModal from './ChatAgentModal.vue';
import ChatAgentRow from './ChatAgentRow.vue';
import BaseSettingsHeader from '../components/BaseSettingsHeader.vue';

const store = useStore();
const { t } = useI18n();

const showModal = ref(false);
const showDeleteConfirmation = ref(false);
const selectedAgent = ref(null);
const modalMode = ref('create');

const chatAgents = computed(() => store.getters['chatAgents/getRecords']);
const uiFlags = computed(() => store.getters['chatAgents/getUIFlags']);

const tableHeaders = computed(() => [
  t('CHAT_AGENTS.TABLE.NAME'),
  t('CHAT_AGENTS.TABLE.WEBHOOK_URL'),
  t('CHAT_AGENTS.TABLE.STATUS'),
]);

const openCreateModal = () => {
  selectedAgent.value = null;
  modalMode.value = 'create';
  showModal.value = true;
};

const openEditModal = agent => {
  selectedAgent.value = agent;
  modalMode.value = 'update';
  showModal.value = true;
};

const closeModal = () => {
  showModal.value = false;
  selectedAgent.value = null;
};

const openDeletePopup = agent => {
  selectedAgent.value = agent;
  showDeleteConfirmation.value = true;
};

const closeDeletePopup = () => {
  showDeleteConfirmation.value = false;
  selectedAgent.value = null;
};

const confirmDeletion = async () => {
  try {
    await store.dispatch('chatAgents/delete', selectedAgent.value.id);
    useAlert(t('CHAT_AGENTS.DELETE.SUCCESS'));
    closeDeletePopup();
  } catch (error) {
    useAlert(t('CHAT_AGENTS.DELETE.ERROR'));
  }
};

onMounted(() => {
  store.dispatch('chatAgents/get');
});
</script>

<template>
  <div class="flex flex-col flex-1 gap-8 overflow-auto">
    <BaseSettingsHeader
      :title="$t('CHAT_AGENTS.HEADER.TITLE')"
      :description="$t('CHAT_AGENTS.HEADER.DESCRIPTION')"
      :link-text="$t('CHAT_AGENTS.LEARN_MORE')"
      feature-name="chat_agents"
      :back-button-label="$t('SIDEBAR.SETTINGS')"
    >
      <template #actions>
        <Button
          icon="i-lucide-circle-plus"
          :label="$t('CHAT_AGENTS.HEADER.ADD_BUTTON')"
          @click="openCreateModal"
        />
      </template>
    </BaseSettingsHeader>

    <div class="w-full overflow-x-auto text-n-slate-11">
      <p
        v-if="!uiFlags.isFetching && !chatAgents.length"
        class="flex flex-col items-center justify-center h-full"
      >
        {{ $t('CHAT_AGENTS.LIST_EMPTY_STATE.DESCRIPTION') }}
      </p>

      <woot-loading-state
        v-if="uiFlags.isFetching"
        :message="$t('CHAT_AGENTS.LOADING')"
      />

      <table
        v-if="!uiFlags.isFetching && chatAgents.length"
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
          <ChatAgentRow
            v-for="(agent, index) in chatAgents"
            :key="agent.id"
            :index="index"
            :agent="agent"
            @edit="openEditModal"
            @delete="openDeletePopup"
          />
        </tbody>
      </table>
    </div>

    <ChatAgentModal
      v-if="showModal"
      :show="showModal"
      :mode="modalMode"
      :selected-agent="selectedAgent"
      @close="closeModal"
    />

    <woot-delete-modal
      v-model:show="showDeleteConfirmation"
      :on-close="closeDeletePopup"
      :on-confirm="confirmDeletion"
      :title="$t('CHAT_AGENTS.DELETE.TITLE')"
      :message="$t('CHAT_AGENTS.DELETE.CONFIRM', { name: selectedAgent?.title || '' })"
      :confirm-text="$t('CHAT_AGENTS.DELETE.CONFIRM_YES')"
      :reject-text="$t('CHAT_AGENTS.DELETE.CONFIRM_NO')"
    />
  </div>
</template>
