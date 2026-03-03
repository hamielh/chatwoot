import ScheduledMessagesAPI from '../../api/scheduledMessages';

const state = {
  records: {},
  uiFlags: {
    isFetching: false,
    isCreating: false,
  },
};

export const getters = {
  getScheduledMessages: $state => conversationId => {
    return $state.records[conversationId] || [];
  },
  getUIFlags: $state => $state.uiFlags,
};

export const actions = {
  fetch: async ({ commit }, { conversationId }) => {
    commit('SET_UI_FLAGS', { isFetching: true });
    try {
      const { data } = await ScheduledMessagesAPI.get(conversationId);
      commit('SET_SCHEDULED_MESSAGES', { conversationId, data });
    } catch (error) {
      // silent
    } finally {
      commit('SET_UI_FLAGS', { isFetching: false });
    }
  },

  create: async (
    { commit },
    { conversationId, content, scheduledAt, files, isPrivate }
  ) => {
    commit('SET_UI_FLAGS', { isCreating: true });
    try {
      const { data } = await ScheduledMessagesAPI.create(conversationId, {
        content,
        scheduledAt,
        files,
        isPrivate,
      });
      commit('ADD_SCHEDULED_MESSAGE', { conversationId, data });
      return data;
    } finally {
      commit('SET_UI_FLAGS', { isCreating: false });
    }
  },

  cancel: async ({ commit }, { conversationId, id }) => {
    await ScheduledMessagesAPI.cancel(conversationId, id);
    commit('REMOVE_SCHEDULED_MESSAGE', { conversationId, id });
  },
};

export const mutations = {
  SET_UI_FLAGS($state, flags) {
    $state.uiFlags = { ...$state.uiFlags, ...flags };
  },
  SET_SCHEDULED_MESSAGES($state, { conversationId, data }) {
    $state.records = { ...$state.records, [conversationId]: data };
  },
  ADD_SCHEDULED_MESSAGE($state, { conversationId, data }) {
    const existing = $state.records[conversationId] || [];
    $state.records = {
      ...$state.records,
      [conversationId]: [...existing, data],
    };
  },
  REMOVE_SCHEDULED_MESSAGE($state, { conversationId, id }) {
    const existing = $state.records[conversationId] || [];
    $state.records = {
      ...$state.records,
      [conversationId]: existing.filter(m => m.id !== id),
    };
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
