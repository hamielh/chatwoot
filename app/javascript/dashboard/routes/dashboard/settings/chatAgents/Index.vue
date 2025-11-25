<script setup>
import { ref, computed, onMounted } from 'vue';
import { useStore } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import Button from 'dashboard/components-next/button/Button.vue';
import ChatAgentModal from './ChatAgentModal.vue';
import ChatAgentRow from './ChatAgentRow.vue';

const store = useStore();
const { t } = useI18n();

const showModal = ref(false);
const selectedAgent = ref(null);
const modalMode = ref('create');

const chatAgents = computed(() => store.getters['chatAgents/getRecords']);
const uiFlags = computed(() => store.getters['chatAgents/getUIFlags']);

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

const deleteAgent = async agent => {
  if (!confirm(t('CHAT_AGENTS.DELETE.CONFIRM', { name: agent.title }))) return;

  try {
    await store.dispatch('chatAgents/delete', agent.id);
    useAlert(t('CHAT_AGENTS.DELETE.SUCCESS'));
  } catch (error) {
    useAlert(t('CHAT_AGENTS.DELETE.ERROR'));
  }
};

onMounted(() => {
  store.dispatch('chatAgents/get');
});
</script>

<template>
  <div class="flex-1 overflow-auto p-8">
    <div class="w-full max-w-6xl mx-auto">
      <!-- Header -->
      <div class="flex items-center justify-between mb-6">
        <div>
          <h1 class="text-2xl font-semibold text-n-slate-12 mb-1">
            {{ $t('CHAT_AGENTS.HEADER.TITLE') }}
          </h1>
          <p class="text-sm text-n-slate-11">
            {{ $t('CHAT_AGENTS.HEADER.DESCRIPTION') }}
          </p>
        </div>
        <Button
          icon="i-lucide-plus"
          @click="openCreateModal"
        >
          {{ $t('CHAT_AGENTS.HEADER.ADD_BUTTON') }}
        </Button>
      </div>

      <!-- Loading -->
      <div
        v-if="uiFlags.isFetching"
        class="flex items-center justify-center py-12"
      >
        <span class="i-lucide-loader-2 animate-spin text-2xl text-n-slate-11" />
      </div>

      <!-- Empty State -->
      <div
        v-else-if="chatAgents.length === 0"
        class="flex flex-col items-center justify-center py-12 text-center"
      >
        <span class="i-lucide-bot text-6xl text-n-slate-9 mb-4" />
        <h3 class="text-lg font-medium text-n-slate-12 mb-2">
          {{ $t('CHAT_AGENTS.EMPTY_STATE.TITLE') }}
        </h3>
        <p class="text-sm text-n-slate-11 mb-6 max-w-md">
          {{ $t('CHAT_AGENTS.EMPTY_STATE.DESCRIPTION') }}
        </p>
        <Button
          icon="i-lucide-plus"
          @click="openCreateModal"
        >
          {{ $t('CHAT_AGENTS.EMPTY_STATE.ADD_BUTTON') }}
        </Button>
      </div>

      <!-- Table -->
      <div v-else class="border border-n-border rounded-lg overflow-hidden">
        <table class="w-full">
          <thead class="bg-n-alpha-2">
            <tr>
              <th class="text-left py-3 px-4 text-xs font-medium text-n-slate-11 uppercase tracking-wider">
                {{ $t('CHAT_AGENTS.TABLE.NAME') }}
              </th>
              <th class="text-left py-3 px-4 text-xs font-medium text-n-slate-11 uppercase tracking-wider">
                {{ $t('CHAT_AGENTS.TABLE.WEBHOOK_URL') }}
              </th>
              <th class="text-left py-3 px-4 text-xs font-medium text-n-slate-11 uppercase tracking-wider">
                {{ $t('CHAT_AGENTS.TABLE.STATUS') }}
              </th>
              <th class="text-right py-3 px-4 text-xs font-medium text-n-slate-11 uppercase tracking-wider">
                {{ $t('CHAT_AGENTS.TABLE.ACTIONS') }}
              </th>
            </tr>
          </thead>
          <tbody class="divide-y divide-n-border">
            <ChatAgentRow
              v-for="(agent, index) in chatAgents"
              :key="agent.id"
              :agent="agent"
              :index="index"
              @edit="openEditModal"
              @delete="deleteAgent"
            />
          </tbody>
        </table>
      </div>
    </div>

    <!-- Modal -->
    <ChatAgentModal
      :show="showModal"
      :mode="modalMode"
      :selected-agent="selectedAgent"
      @close="closeModal"
    />
  </div>
</template>
