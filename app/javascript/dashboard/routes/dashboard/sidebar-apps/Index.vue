<script setup>
import { computed, onMounted } from 'vue';
import { useRoute } from 'vue-router';
import { useStore } from 'vuex';
import SidebarAppFrame from './SidebarAppFrame.vue';

const route = useRoute();
const store = useStore();

const appId = computed(() => parseInt(route.params.appId, 10));

const app = computed(() => {
  return store.getters['sidebarApps/getAppById'](appId.value);
});

onMounted(() => {
  // Ensure apps are loaded
  if (!store.getters['sidebarApps/getRecords'].length) {
    store.dispatch('sidebarApps/get');
  }
});
</script>

<template>
  <div class="flex flex-col w-full h-full">
    <div v-if="!app" class="flex items-center justify-center w-full h-full">
      <p class="text-n-slate-11">
        {{ $t('SIDEBAR_APPS.APP_NOT_FOUND') }}
      </p>
    </div>
    <SidebarAppFrame v-else :app="app" />
  </div>
</template>
