<script setup>
import { computed } from 'vue';
import { useStore } from 'dashboard/composables/store';
import Button from 'dashboard/components-next/button/Button.vue';
import ButtonGroup from 'dashboard/components-next/button/ButtonGroup.vue';

const store = useStore();

const chatAgents = computed(() => store.getters['chatAgents/getRecords']);
const currentRole = computed(() => store.getters.getCurrentRole);
const isChatAgentOpen = computed(() => store.getters['chatAgentUI/isOpen']);

const availableAgents = computed(() => {
  return chatAgents.value.filter(agent => {
    if (!agent.enabled) return false;
    if (agent.allowed_roles.length === 0) return true;
    return agent.allowed_roles.includes(currentRole.value);
  });
});

const showLauncher = computed(() => {
  return availableAgents.value.length > 0 && !isChatAgentOpen.value;
});

const toggleChatAgent = () => {
  store.dispatch('chatAgentUI/toggle');
};
</script>

<template>
  <div
    v-if="showLauncher"
    class="fixed bottom-20 ltr:right-4 rtl:left-4 z-50"
  >
    <ButtonGroup
      class="rounded-full bg-n-alpha-2 backdrop-blur-lg p-1 shadow hover:shadow-md"
    >
      <Button
        icon="i-lucide-bot"
        no-animation
        class="!rounded-full !bg-n-solid-3 dark:!bg-n-alpha-2 !text-n-slate-12 text-xl transition-all duration-200 ease-out hover:brightness-110"
        lg
        @click="toggleChatAgent"
      />
    </ButtonGroup>
  </div>
</template>
