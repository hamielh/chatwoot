<script setup>
import { ref, computed, watch, onMounted, nextTick } from 'vue';
import { useStore } from 'dashboard/composables/store';
import { useI18n } from 'vue-i18n';
import { useAlert } from 'dashboard/composables';
import { vOnClickOutside } from '@vueuse/components';
import Button from 'dashboard/components-next/button/Button.vue';
import TextArea from 'dashboard/components-next/textarea/TextArea.vue';

const store = useStore();
const { t } = useI18n();

const messageInput = ref('');
const messagesContainer = ref(null);
const isDropdownOpen = ref(false);

const isOpen = computed(() => store.getters['chatAgentUI/isOpen']);
const chatAgents = computed(() => store.getters['chatAgents/getRecords']);
const selectedAgentId = computed(() => store.getters['chatAgents/getSelectedAgentId']);
const messages = computed(() => {
  if (!selectedAgentId.value) return [];
  return store.getters['chatAgents/getMessages'](selectedAgentId.value);
});
const uiFlags = computed(() => store.getters['chatAgents/getUIFlags']);
const currentRole = computed(() => store.getters.getCurrentRole);

const availableAgents = computed(() => {
  return chatAgents.value
    .filter(agent => {
      if (!agent.enabled) return false;
      if (agent.allowed_roles.length === 0) return true;
      return agent.allowed_roles.includes(currentRole.value);
    })
    .map(agent => ({
      id: agent.id,
      label: agent.title,
      icon: agent.icon,
    }));
});

const scrollToBottom = () => {
  if (messagesContainer.value) {
    messagesContainer.value.scrollTop = messagesContainer.value.scrollHeight;
  }
};

const loadMessages = async agentId => {
  try {
    await store.dispatch('chatAgents/fetchMessages', agentId);
    await nextTick();
    scrollToBottom();
  } catch (error) {
    useAlert(t('CHAT_AGENTS.ERROR.FETCH_MESSAGES'));
  }
};

const selectedAgent = computed({
  get: () => {
    if (!selectedAgentId.value) return null;
    return availableAgents.value.find(a => a.id === selectedAgentId.value);
  },
  set: (agent) => {
    if (agent) {
      store.dispatch('chatAgents/setSelectedAgent', agent.id);
      loadMessages(agent.id);
    }
  },
});

const headerTitle = computed(() => {
  if (selectedAgent.value) {
    return selectedAgent.value.label;
  }
  return t('CHAT_AGENTS.TITLE');
});

const headerIconClass = computed(() => {
  const icon = selectedAgent.value?.icon || 'i-lucide-bot';
  return `${icon} text-xl text-n-slate-11`;
});

const toggleDropdown = () => {
  isDropdownOpen.value = !isDropdownOpen.value;
};

const selectAgent = (agent) => {
  selectedAgent.value = agent;
  isDropdownOpen.value = false;
};

const closeSidebar = () => {
  store.dispatch('chatAgentUI/close');
};

const sendMessage = async () => {
  if (!messageInput.value.trim() || !selectedAgentId.value) return;

  const message = messageInput.value.trim();
  messageInput.value = '';

  try {
    await store.dispatch('chatAgents/sendMessage', {
      agentId: selectedAgentId.value,
      message,
    });
    await nextTick();
    scrollToBottom();
  } catch (error) {
    useAlert(t('CHAT_AGENTS.ERROR.SEND_MESSAGE'));
  }
};

const clearHistory = async () => {
  if (!selectedAgentId.value) return;

  try {
    await store.dispatch('chatAgents/clearMessages', selectedAgentId.value);
    useAlert(t('CHAT_AGENTS.SUCCESS.CLEAR_MESSAGES'));
  } catch (error) {
    useAlert(t('CHAT_AGENTS.ERROR.CLEAR_MESSAGES'));
  }
};

const formatTime = timestamp => {
  const date = new Date(timestamp * 1000);
  const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  const month = months[date.getMonth()];
  const day = date.getDate();
  const hours = date.getHours();
  const minutes = date.getMinutes().toString().padStart(2, '0');
  return `${month} ${day}, ${hours}:${minutes}`;
};

watch(isOpen, async newValue => {
  if (newValue && availableAgents.value.length > 0) {
    if (!selectedAgentId.value) {
      const firstAgent = availableAgents.value[0];
      store.dispatch('chatAgents/setSelectedAgent', firstAgent.id);
      await loadMessages(firstAgent.id);
    }
  }
});

// Auto-scroll when new messages arrive
watch(messages, async () => {
  await nextTick();
  scrollToBottom();
}, { deep: true });

onMounted(() => {
  store.dispatch('chatAgents/get');
});
</script>

<template>
  <div
    v-if="isOpen"
    class="bg-n-background h-full overflow-hidden flex flex-col fixed top-0 ltr:right-0 rtl:left-0 z-40 w-full max-w-sm transition-transform duration-300 ease-in-out md:static md:w-[320px] md:min-w-[320px] ltr:border-l rtl:border-r border-n-weak 2xl:min-w-[360px] 2xl:w-[360px] shadow-lg md:shadow-none"
  >
    <!-- Header -->
    <div class="flex items-center justify-between p-4 border-b border-n-weak relative">
      <div class="flex items-center gap-2 flex-1">
        <span :class="headerIconClass" />
        <h2 class="text-base font-semibold text-n-slate-12">
          {{ headerTitle }}
        </h2>
      </div>

      <div class="flex items-center gap-1">
        <Button
          v-if="availableAgents.length > 0"
          :icon="isDropdownOpen ? 'i-lucide-chevron-up' : 'i-lucide-chevron-down'"
          xs
          slate
          faded
          @click="toggleDropdown"
        />
        <Button
          v-if="selectedAgentId"
          v-tooltip.top="$t('CHAT_AGENTS.CLEAR_HISTORY')"
          icon="i-lucide-trash-2"
          xs
          slate
          faded
          :loading="uiFlags.isClearingMessages"
          @click="clearHistory"
        />
        <Button
          v-tooltip.top="$t('CHAT_AGENTS.CLOSE')"
          icon="i-lucide-x"
          xs
          slate
          faded
          @click="closeSidebar"
        />
      </div>

      <!-- Dropdown Menu -->
      <div
        v-if="isDropdownOpen"
        v-on-click-outside="() => isDropdownOpen = false"
        class="absolute top-full left-0 right-0 mt-1 bg-n-background border border-n-weak rounded-lg shadow-lg z-50 max-h-64 overflow-y-auto mx-4"
      >
        <button
          v-for="agent in availableAgents"
          :key="agent.id"
          class="w-full flex items-center gap-3 px-4 py-3 hover:bg-n-slate-2 transition-colors text-left"
          :class="{ 'bg-n-slate-3': selectedAgentId === agent.id }"
          @click="selectAgent(agent)"
        >
          <span :class="[agent.icon, 'text-lg text-n-slate-11']" />
          <span class="text-sm text-n-slate-12 font-medium">{{ agent.label }}</span>
          <span
            v-if="selectedAgentId === agent.id"
            class="i-lucide-check text-base text-woot-500 ml-auto"
          />
        </button>
      </div>
    </div>

    <!-- Messages -->
    <div
      ref="messagesContainer"
      class="flex-1 overflow-y-auto p-4 space-y-2"
    >
      <div
        v-if="uiFlags.isFetchingMessages"
        class="flex items-center justify-center h-full"
      >
        <span class="i-lucide-loader-2 animate-spin text-2xl text-n-slate-11" />
      </div>

      <div
        v-else-if="messages.length === 0"
        class="flex flex-col items-center justify-center h-full text-center"
      >
        <span class="i-lucide-message-square text-4xl text-n-slate-9 mb-2" />
        <p class="text-sm text-n-slate-11">
          {{ $t('CHAT_AGENTS.EMPTY_STATE') }}
        </p>
      </div>

      <template v-else>
        <div
          v-for="message in messages"
          :key="message.id"
          class="flex mb-2"
          :class="message.role === 'user' ? 'justify-end' : 'justify-start'"
        >
        <div
          class="max-w-[75%] px-4 py-2.5 shadow-sm"
          :class="
            message.role === 'user'
              ? 'bg-woot-500 text-white rounded-2xl rounded-br-md'
              : 'bg-n-slate-3 text-n-slate-12 rounded-2xl rounded-bl-md'
          "
        >
          <p class="text-sm leading-relaxed whitespace-pre-wrap break-words">
            {{ message.content }}
          </p>
          <p
            class="text-xs mt-1 opacity-70"
            :class="message.role === 'user' ? 'text-right' : 'text-left'"
          >
            {{ formatTime(message.created_at) }}
          </p>
        </div>
        </div>
      </template>
    </div>

    <!-- Input -->
    <div class="p-4 border-t border-n-weak">
      <div class="flex gap-2">
        <TextArea
          v-model="messageInput"
          :placeholder="$t('CHAT_AGENTS.INPUT_PLACEHOLDER')"
          :disabled="!selectedAgentId || uiFlags.isSendingMessage"
          rows="2"
          class="flex-1"
          @keydown.enter.prevent="sendMessage"
        />
        <Button
          icon="i-lucide-send"
          :disabled="!messageInput.trim() || !selectedAgentId"
          :loading="uiFlags.isSendingMessage"
          @click="sendMessage"
        />
      </div>
    </div>
  </div>
</template>
