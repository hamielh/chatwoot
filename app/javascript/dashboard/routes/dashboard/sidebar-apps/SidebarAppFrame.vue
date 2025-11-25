<script setup>
import { computed, ref } from 'vue';
import { useStore } from 'vuex';
import LoadingState from 'dashboard/components/widgets/LoadingState.vue';

const props = defineProps({
  app: {
    type: Object,
    required: true,
  },
});

const store = useStore();
const iframeLoading = ref(true);

const currentUser = computed(() => store.getters.getCurrentUser);
const currentAccount = computed(() => store.getters.getCurrentAccountId);
const accountName = computed(() => store.getters.getAccount?.name || '');

const iframeUrl = computed(() => {
  const url = new URL(props.app.url);

  // Add query parameters
  url.searchParams.set('account_id', currentAccount.value);
  url.searchParams.set('account_name', accountName.value);
  url.searchParams.set('agent_id', currentUser.value.id);
  url.searchParams.set('agent_name', currentUser.value.name);
  url.searchParams.set('agent_email', currentUser.value.email);

  return url.toString();
});

const onIframeLoad = () => {
  iframeLoading.value = false;
};
</script>

<template>
  <div class="flex flex-col w-full h-full bg-n-background">
    <LoadingState
      v-if="iframeLoading"
      :message="$t('SIDEBAR_APPS.LOADING_MESSAGE')"
      class="flex items-center justify-center w-full h-full"
    />
    <iframe
      v-show="!iframeLoading"
      :src="iframeUrl"
      class="w-full h-full border-0"
      @load="onIframeLoad"
    />
  </div>
</template>
