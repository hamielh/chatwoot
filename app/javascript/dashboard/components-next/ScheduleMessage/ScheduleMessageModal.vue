<script setup>
import { ref, computed } from 'vue';
import { useI18n } from 'vue-i18n';
import { useStore } from 'dashboard/composables/store';
import { useAlert } from 'dashboard/composables';
import DatePicker from 'vue-datepicker-next';
import NextButton from 'dashboard/components-next/button/Button.vue';

const props = defineProps({
  conversationId: {
    type: [Number, String],
    required: true,
  },
});

const { t } = useI18n();
const store = useStore();

const showModal = ref(false);
const content = ref('');
const scheduledAt = ref(null);
const attachedFiles = ref([]);
const isPrivate = ref(false);
const fileInput = ref(null);

const scheduledMessages = computed(() =>
  store.getters['scheduledMessages/getScheduledMessages'](props.conversationId)
);
const uiFlags = computed(() => store.getters['scheduledMessages/getUIFlags']);

const lang = {
  days: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'],
  yearFormat: 'YYYY',
  monthFormat: 'MMMM',
};

const disabledDate = date => {
  const yesterday = new Date();
  yesterday.setDate(yesterday.getDate() - 1);
  return date < yesterday;
};

const disabledTime = date => {
  const now = new Date();
  now.setMinutes(now.getMinutes() + 5);
  return date < now;
};

const hasContent = computed(
  () => content.value.trim() || attachedFiles.value.length > 0
);
const canSubmit = computed(
  () => hasContent.value && scheduledAt.value && !uiFlags.value.isCreating
);

const open = () => {
  showModal.value = true;
  store.dispatch('scheduledMessages/fetch', {
    conversationId: props.conversationId,
  });
};

const close = () => {
  showModal.value = false;
  content.value = '';
  scheduledAt.value = null;
  attachedFiles.value = [];
  isPrivate.value = false;
};

const onFileSelect = event => {
  const files = Array.from(event.target.files);
  files.forEach(file => {
    attachedFiles.value.push(file);
  });
  event.target.value = '';
};

const removeFile = index => {
  attachedFiles.value.splice(index, 1);
};

const formatFileSize = bytes => {
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(1)} KB`;
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
};

const scheduleMessage = async () => {
  if (!canSubmit.value) return;
  try {
    await store.dispatch('scheduledMessages/create', {
      conversationId: props.conversationId,
      content: content.value,
      scheduledAt: scheduledAt.value.toISOString(),
      files: attachedFiles.value,
      isPrivate: isPrivate.value,
    });
    useAlert(t('SCHEDULED_MESSAGE.CREATE.SUCCESS'));
    content.value = '';
    scheduledAt.value = null;
    attachedFiles.value = [];
    isPrivate.value = false;
  } catch (error) {
    useAlert(t('SCHEDULED_MESSAGE.CREATE.ERROR'));
  }
};

const cancelMessage = async id => {
  try {
    await store.dispatch('scheduledMessages/cancel', {
      conversationId: props.conversationId,
      id,
    });
    useAlert(t('SCHEDULED_MESSAGE.CANCEL.SUCCESS'));
  } catch (error) {
    useAlert(t('SCHEDULED_MESSAGE.CANCEL.ERROR'));
  }
};

const formatDate = dateStr => {
  const date = new Date(dateStr);
  return date.toLocaleString();
};

defineExpose({ open });
</script>

<template>
  <teleport to="body">
    <div
      v-if="showModal"
      class="fixed inset-0 z-50 bg-n-alpha-black1 backdrop-blur-[4px] flex items-start pt-[clamp(3rem,15vh,12rem)] justify-center"
      @click.self="close"
    >
      <div
        class="w-[42rem] flex flex-col bg-n-alpha-3 border border-n-strong shadow-sm backdrop-blur-[100px] rounded-xl max-h-[calc(100vh-8rem)] overflow-y-auto"
      >
        <!-- Header -->
        <div
          class="flex items-center justify-between p-4 border-b border-n-strong"
        >
          <div>
            <h3 class="text-base font-medium text-n-slate-12">
              {{ $t('SCHEDULED_MESSAGE.TITLE') }}
            </h3>
            <p class="text-xs text-n-slate-10 mt-0.5">
              {{ $t('SCHEDULED_MESSAGE.SUBTITLE') }}
            </p>
          </div>
          <NextButton icon="i-lucide-x" xs slate faded @click="close" />
        </div>

        <div class="p-4 space-y-4">
          <!-- Date Picker -->
          <DatePicker
            v-model:value="scheduledAt"
            type="datetime"
            :show-second="false"
            :placeholder="$t('SCHEDULED_MESSAGE.FORM.DATE_PLACEHOLDER')"
            input-class="w-full p-3 text-sm border rounded-lg border-n-strong bg-n-alpha-1 text-n-slate-12 focus:outline-none focus:ring-1 focus:ring-n-brand"
            :lang="lang"
            :disabled-date="disabledDate"
            :disabled-time="disabledTime"
          />

          <!-- Textarea -->
          <textarea
            v-model="content"
            class="w-full p-3 text-sm border rounded-lg border-n-strong bg-n-alpha-1 text-n-slate-12 resize-none focus:outline-none focus:ring-1 focus:ring-n-brand"
            rows="3"
            :placeholder="$t('SCHEDULED_MESSAGE.FORM.CONTENT_PLACEHOLDER')"
          />

          <!-- Attached files preview -->
          <div v-if="attachedFiles.length" class="flex flex-wrap gap-2">
            <div
              v-for="(file, index) in attachedFiles"
              :key="index"
              class="flex items-center gap-2 px-3 py-1.5 rounded-lg bg-n-alpha-1 border border-n-strong text-xs text-n-slate-11"
            >
              <span class="i-lucide-file w-3.5 h-3.5 shrink-0" />
              <span class="truncate max-w-[10rem]">{{ file.name }}</span>
              <span class="text-n-slate-9">{{
                `(${formatFileSize(file.size)})`
              }}</span>
              <button
                class="i-lucide-x w-3.5 h-3.5 shrink-0 text-n-slate-9 hover:text-n-ruby-9 cursor-pointer"
                @click="removeFile(index)"
              />
            </div>
          </div>

          <!-- Bottom bar: attach + private checkbox + schedule button -->
          <div class="flex items-center justify-between">
            <div class="flex items-center gap-3">
              <input
                ref="fileInput"
                type="file"
                multiple
                class="hidden"
                @change="onFileSelect"
              />
              <NextButton
                v-tooltip.top="$t('SCHEDULED_MESSAGE.FORM.ATTACH')"
                icon="i-lucide-paperclip"
                xs
                slate
                faded
                @click="fileInput.click()"
              />
              <label
                class="flex items-center gap-1.5 cursor-pointer select-none"
              >
                <input
                  v-model="isPrivate"
                  type="checkbox"
                  class="w-3.5 h-3.5 rounded border-n-strong accent-n-brand cursor-pointer"
                />
                <span class="text-xs text-n-slate-11">
                  {{ $t('SCHEDULED_MESSAGE.FORM.PRIVATE') }}
                </span>
              </label>
            </div>
            <NextButton
              :label="$t('SCHEDULED_MESSAGE.FORM.SCHEDULE')"
              icon="i-lucide-calendar-plus"
              :disabled="!canSubmit"
              :is-loading="uiFlags.isCreating"
              @click="scheduleMessage"
            />
          </div>

          <!-- Scheduled messages list -->
          <div
            v-if="scheduledMessages.length"
            class="border-t border-n-strong pt-4"
          >
            <h4 class="text-sm font-medium text-n-slate-11 mb-3">
              {{ $t('SCHEDULED_MESSAGE.LIST.TITLE') }}
            </h4>
            <div class="space-y-2 max-h-48 overflow-y-auto">
              <div
                v-for="msg in scheduledMessages"
                :key="msg.id"
                class="flex items-start justify-between p-3 rounded-lg bg-n-alpha-1"
              >
                <div class="flex-1 min-w-0 mr-3">
                  <p class="text-sm text-n-slate-12 truncate">
                    {{
                      msg.content ||
                      $t('SCHEDULED_MESSAGE.LIST.ATTACHMENT_ONLY')
                    }}
                  </p>
                  <div class="flex items-center gap-2 mt-1">
                    <span
                      v-if="msg.attachments && msg.attachments.length"
                      class="flex items-center gap-1"
                    >
                      <span class="i-lucide-paperclip w-3 h-3 text-n-slate-9" />
                      <span class="text-xs text-n-slate-9">
                        {{ msg.attachments.length }}
                        {{
                          msg.attachments.length === 1
                            ? $t('SCHEDULED_MESSAGE.LIST.FILE')
                            : $t('SCHEDULED_MESSAGE.LIST.FILES')
                        }}
                      </span>
                    </span>
                    <span
                      v-if="msg.private"
                      class="text-xs text-n-amber-9 font-medium"
                    >
                      {{ $t('SCHEDULED_MESSAGE.LIST.PRIVATE') }}
                    </span>
                  </div>
                  <span class="text-xs text-n-slate-10">
                    {{ formatDate(msg.scheduled_at) }}
                  </span>
                </div>
                <NextButton
                  v-tooltip.top="$t('SCHEDULED_MESSAGE.CANCEL.BUTTON')"
                  icon="i-lucide-x"
                  xs
                  ruby
                  faded
                  @click="cancelMessage(msg.id)"
                />
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </teleport>
</template>
