<script setup>
import Button from 'dashboard/components-next/button/Button.vue';

defineProps({
  app: {
    type: Object,
    required: true,
  },
});

defineEmits(['edit', 'delete']);

const displayLocationLabel = location => {
  return location === 'root'
    ? 'SIDEBAR_APPS.LOCATION.ROOT'
    : 'SIDEBAR_APPS.LOCATION.APPS_MENU';
};
</script>

<template>
  <tr>
    <td class="py-4 ltr:pr-4 rtl:pl-4">
      <div class="flex items-center gap-2">
        <span :class="[app.icon || 'i-lucide-app-window', 'text-xl text-n-slate-11']" />
        <span class="font-medium text-n-slate-12">{{ app.title }}</span>
      </div>
    </td>
    <td class="py-4 ltr:pr-4 rtl:pl-4">
      <span class="text-n-slate-11">{{ app.url }}</span>
    </td>
    <td class="py-4 ltr:pr-4 rtl:pl-4">
      <span class="text-n-slate-11">{{
        $t(displayLocationLabel(app.display_location))
      }}</span>
    </td>
    <td class="py-4 text-right ltr:pr-4 rtl:pl-4">
      <div class="flex items-center justify-end gap-1">
        <Button
          v-tooltip.top="$t('SIDEBAR_APPS.EDIT.BUTTON_TEXT')"
          icon="i-lucide-pen"
          slate
          xs
          faded
          @click="$emit('edit', app)"
        />
        <Button
          v-tooltip.top="$t('SIDEBAR_APPS.DELETE.BUTTON_TEXT')"
          icon="i-lucide-trash-2"
          xs
          ruby
          faded
          @click="$emit('delete', app)"
        />
      </div>
    </td>
  </tr>
</template>
