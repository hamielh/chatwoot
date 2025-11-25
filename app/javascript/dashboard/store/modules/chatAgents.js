import Vue from 'vue';
import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import types from '../mutation-types';
import ChatAgentsAPI from '../../api/chatAgents';

export const state = {
  records: [],
  messages: {},
  selectedAgentId: null,
  uiFlags: {
    isFetching: false,
    isFetchingMessages: false,
    isSendingMessage: false,
    isClearingMessages: false,
    isCreating: false,
    isUpdating: false,
    isDeleting: false,
  },
};

export const getters = {
  getRecords(_state) {
    return _state.records;
  },
  getUIFlags(_state) {
    return _state.uiFlags;
  },
  getSelectedAgentId(_state) {
    return _state.selectedAgentId;
  },
  getMessages: _state => agentId => {
    return _state.messages[agentId] || [];
  },
};

export const actions = {
  get: async function getChatAgents({ commit }) {
    commit(types.SET_CHAT_AGENTS_UI_FLAG, { isFetching: true });
    try {
      const response = await ChatAgentsAPI.get();
      commit(types.SET_CHAT_AGENTS, response.data);
    } catch (error) {
      // Ignore error
    } finally {
      commit(types.SET_CHAT_AGENTS_UI_FLAG, { isFetching: false });
    }
  },

  create: async function createChatAgent({ commit }, agentObj) {
    commit(types.SET_CHAT_AGENTS_UI_FLAG, { isCreating: true });
    try {
      const response = await ChatAgentsAPI.create(agentObj);
      commit(types.ADD_CHAT_AGENT, response.data);
      return response.data;
    } catch (error) {
      throw error;
    } finally {
      commit(types.SET_CHAT_AGENTS_UI_FLAG, { isCreating: false });
    }
  },

  update: async function updateChatAgent({ commit }, { id, ...agentObj }) {
    commit(types.SET_CHAT_AGENTS_UI_FLAG, { isUpdating: true });
    try {
      const response = await ChatAgentsAPI.update(id, agentObj);
      commit(types.EDIT_CHAT_AGENT, response.data);
      return response.data;
    } catch (error) {
      throw error;
    } finally {
      commit(types.SET_CHAT_AGENTS_UI_FLAG, { isUpdating: false });
    }
  },

  delete: async function deleteChatAgent({ commit }, id) {
    commit(types.SET_CHAT_AGENTS_UI_FLAG, { isDeleting: true });
    try {
      await ChatAgentsAPI.delete(id);
      commit(types.DELETE_CHAT_AGENT, id);
    } catch (error) {
      throw error;
    } finally {
      commit(types.SET_CHAT_AGENTS_UI_FLAG, { isDeleting: false });
    }
  },

  fetchMessages: async function fetchMessages({ commit }, agentId) {
    commit(types.SET_CHAT_AGENTS_UI_FLAG, { isFetchingMessages: true });
    try {
      const response = await ChatAgentsAPI.getMessages(agentId);
      commit(types.SET_CHAT_AGENT_MESSAGES, { agentId, messages: response.data });
    } catch (error) {
      throw error;
    } finally {
      commit(types.SET_CHAT_AGENTS_UI_FLAG, { isFetchingMessages: false });
    }
  },

  sendMessage: async function sendMessage({ commit }, { agentId, message }) {
    commit(types.SET_CHAT_AGENTS_UI_FLAG, { isSendingMessage: true });
    try {
      const response = await ChatAgentsAPI.sendMessage(agentId, message);
      commit(types.ADD_CHAT_AGENT_MESSAGES, { agentId, messages: response.data });
      return response.data;
    } catch (error) {
      throw error;
    } finally {
      commit(types.SET_CHAT_AGENTS_UI_FLAG, { isSendingMessage: false });
    }
  },

  clearMessages: async function clearMessages({ commit }, agentId) {
    commit(types.SET_CHAT_AGENTS_UI_FLAG, { isClearingMessages: true });
    try {
      await ChatAgentsAPI.clearMessages(agentId);
      commit(types.CLEAR_CHAT_AGENT_MESSAGES, agentId);
    } catch (error) {
      throw error;
    } finally {
      commit(types.SET_CHAT_AGENTS_UI_FLAG, { isClearingMessages: false });
    }
  },

  setSelectedAgent: function setSelectedAgent({ commit }, agentId) {
    commit(types.SET_SELECTED_CHAT_AGENT, agentId);
  },
};

export const mutations = {
  [types.SET_CHAT_AGENTS_UI_FLAG](_state, data) {
    _state.uiFlags = {
      ..._state.uiFlags,
      ...data,
    };
  },

  [types.SET_CHAT_AGENTS]: MutationHelpers.set,
  [types.ADD_CHAT_AGENT]: MutationHelpers.create,
  [types.EDIT_CHAT_AGENT]: MutationHelpers.update,
  [types.DELETE_CHAT_AGENT]: MutationHelpers.destroy,

  [types.SET_CHAT_AGENT_MESSAGES](_state, { agentId, messages }) {
    Vue.set(_state.messages, agentId, messages);
  },

  [types.ADD_CHAT_AGENT_MESSAGES](_state, { agentId, messages }) {
    const currentMessages = _state.messages[agentId] || [];
    Vue.set(_state.messages, agentId, [...currentMessages, ...messages]);
  },

  [types.CLEAR_CHAT_AGENT_MESSAGES](_state, agentId) {
    Vue.set(_state.messages, agentId, []);
  },

  [types.SET_SELECTED_CHAT_AGENT](_state, agentId) {
    _state.selectedAgentId = agentId;
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
