<script setup>
import { computed } from 'vue';
import Button from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  agent: {
    type: Object,
    required: true,
  },
});

defineEmits(['edit', 'delete']);

const iconClass = computed(() => {
  const icon = props.agent.icon || 'i-lucide-app-window';
  return `${icon} text-xl text-n-slate-11`;
});
</script>

<template>
  <tr>
    <td class="py-4 ltr:pr-4 rtl:pl-4">
      <div class="flex items-center gap-2">
        <span :class="iconClass" />
        <span class="font-medium text-n-slate-12">{{ agent.title }}</span>
      </div>
    </td>
    <td class="py-4 ltr:pr-4 rtl:pl-4">
      <span class="text-n-slate-11">{{ agent.webhook_url }}</span>
    </td>
    <td class="py-4 ltr:pr-4 rtl:pl-4">
      <span class="text-n-slate-11">
        {{ agent.enabled ? $t('CHAT_AGENTS.STATUS.ENABLED') : $t('CHAT_AGENTS.STATUS.DISABLED') }}
      </span>
    </td>
    <td class="py-4 text-right ltr:pr-4 rtl:pl-4">
      <div class="flex items-center justify-end gap-1">
        <Button
          v-tooltip.top="$t('CHAT_AGENTS.EDIT.BUTTON_TEXT')"
          icon="i-lucide-pen"
          slate
          xs
          faded
          @click="$emit('edit', agent)"
        />
        <Button
          v-tooltip.top="$t('CHAT_AGENTS.DELETE.BUTTON_TEXT')"
          icon="i-lucide-trash-2"
          xs
          ruby
          faded
          @click="$emit('delete', agent)"
        />
      </div>
    </td>
  </tr>
</template>
