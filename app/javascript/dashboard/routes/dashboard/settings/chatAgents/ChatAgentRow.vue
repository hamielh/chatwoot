<script setup>
import Button from 'dashboard/components-next/button/Button.vue';

defineProps({
  agent: {
    type: Object,
    required: true,
  },
});

defineEmits(['edit', 'delete']);
</script>

<template>
  <tr class="hover:bg-n-alpha-1">
    <td class="py-4 px-4">
      <div class="flex items-center gap-2">
        <span :class="[agent.icon || 'i-lucide-bot', 'text-xl text-n-slate-11']" />
        <div>
          <div class="font-medium text-n-slate-12">{{ agent.title }}</div>
          <div v-if="agent.description" class="text-xs text-n-slate-11 mt-0.5">
            {{ agent.description }}
          </div>
        </div>
      </div>
    </td>
    <td class="py-4 px-4">
      <span class="text-sm text-n-slate-11 font-mono">{{ agent.webhook_url }}</span>
    </td>
    <td class="py-4 px-4">
      <span
        class="inline-flex items-center px-2 py-1 rounded-full text-xs font-medium"
        :class="
          agent.enabled
            ? 'bg-green-100 dark:bg-green-900/20 text-green-800 dark:text-green-400'
            : 'bg-gray-100 dark:bg-gray-900/20 text-gray-800 dark:text-gray-400'
        "
      >
        {{ agent.enabled ? $t('CHAT_AGENTS.STATUS.ENABLED') : $t('CHAT_AGENTS.STATUS.DISABLED') }}
      </span>
    </td>
    <td class="py-4 px-4 text-right">
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
