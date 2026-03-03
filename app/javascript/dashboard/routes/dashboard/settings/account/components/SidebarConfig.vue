<script setup>
import { ref, watch } from 'vue';
import { useI18n } from 'vue-i18n';
import { useAccount } from 'dashboard/composables/useAccount';
import { useAlert } from 'dashboard/composables';
import SectionLayout from './SectionLayout.vue';
import Switch from 'next/switch/Switch.vue';

const { t } = useI18n();
const { currentAccount, updateAccount } = useAccount();

const SIDEBAR_SECTIONS = [
  { key: 'conversation_actions', label: 'GENERAL_SETTINGS.FORM.SIDEBAR_CONFIG.SECTIONS.CONVERSATION_ACTIONS' },
  { key: 'conversation_participants', label: 'GENERAL_SETTINGS.FORM.SIDEBAR_CONFIG.SECTIONS.CONVERSATION_PARTICIPANTS' },
  { key: 'conversation_info', label: 'GENERAL_SETTINGS.FORM.SIDEBAR_CONFIG.SECTIONS.CONVERSATION_INFO' },
  { key: 'contact_attributes', label: 'GENERAL_SETTINGS.FORM.SIDEBAR_CONFIG.SECTIONS.CONTACT_ATTRIBUTES' },
  { key: 'previous_conversation', label: 'GENERAL_SETTINGS.FORM.SIDEBAR_CONFIG.SECTIONS.PREVIOUS_CONVERSATION' },
  { key: 'macros', label: 'GENERAL_SETTINGS.FORM.SIDEBAR_CONFIG.SECTIONS.MACROS' },
  { key: 'linear_issues', label: 'GENERAL_SETTINGS.FORM.SIDEBAR_CONFIG.SECTIONS.LINEAR_ISSUES' },
  { key: 'shopify_orders', label: 'GENERAL_SETTINGS.FORM.SIDEBAR_CONFIG.SECTIONS.SHOPIFY_ORDERS' },
  { key: 'contact_notes', label: 'GENERAL_SETTINGS.FORM.SIDEBAR_CONFIG.SECTIONS.CONTACT_NOTES' },
];

const sectionStates = ref({});

watch(
  currentAccount,
  () => {
    const config = currentAccount.value?.settings?.sidebar_config || {};
    const states = {};
    SIDEBAR_SECTIONS.forEach(({ key }) => {
      states[key] = config[key] === undefined ? true : !!config[key];
    });
    sectionStates.value = states;
  },
  { deep: true, immediate: true }
);

const toggleSection = async key => {
  const sidebarConfig = { ...sectionStates.value };
  try {
    await updateAccount({ sidebar_config: sidebarConfig });
    useAlert(t('GENERAL_SETTINGS.FORM.SIDEBAR_CONFIG.API.SUCCESS'));
  } catch (error) {
    useAlert(t('GENERAL_SETTINGS.FORM.SIDEBAR_CONFIG.API.ERROR'));
  }
};
</script>

<template>
  <SectionLayout
    :title="t('GENERAL_SETTINGS.FORM.SIDEBAR_CONFIG.TITLE')"
    :description="t('GENERAL_SETTINGS.FORM.SIDEBAR_CONFIG.NOTE')"
    with-border
  >
    <div class="grid gap-3">
      <div
        v-for="section in SIDEBAR_SECTIONS"
        :key="section.key"
        class="flex items-center justify-between py-1.5"
      >
        <span class="text-sm text-n-slate-12">{{ t(section.label) }}</span>
        <Switch
          v-model="sectionStates[section.key]"
          @change="toggleSection(section.key)"
        />
      </div>
    </div>
  </SectionLayout>
</template>
