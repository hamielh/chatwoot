import * as MutationHelpers from 'shared/helpers/vuex/mutationHelpers';
import types from '../mutation-types';
import SidebarAppsAPI from '../../api/sidebarApps';

export const state = {
  records: [],
  uiFlags: {
    isFetching: false,
    isCreating: false,
    isDeleting: false,
    isUpdating: false,
  },
};

export const getters = {
  getUIFlags(_state) {
    return _state.uiFlags;
  },
  getRecords(_state) {
    return _state.records;
  },
  getAppById: _state => id => {
    return _state.records.find(record => record.id === id);
  },
};

export const actions = {
  get: async function getSidebarApps({ commit }) {
    commit(types.SET_SIDEBAR_APPS_UI_FLAG, { isFetching: true });
    try {
      const response = await SidebarAppsAPI.get();
      commit(types.SET_SIDEBAR_APPS, response.data);
    } catch (error) {
      // Ignore error
    } finally {
      commit(types.SET_SIDEBAR_APPS_UI_FLAG, { isFetching: false });
    }
  },
  create: async function createApp({ commit }, appObj) {
    commit(types.SET_SIDEBAR_APPS_UI_FLAG, { isCreating: true });
    try {
      const response = await SidebarAppsAPI.create(appObj);
      commit(types.CREATE_SIDEBAR_APP, response.data);
    } catch (error) {
      const errorMessage = error?.response?.data?.message;
      throw new Error(errorMessage);
    } finally {
      commit(types.SET_SIDEBAR_APPS_UI_FLAG, { isCreating: false });
    }
  },
  update: async function updateApp({ commit }, { id, ...updateObj }) {
    commit(types.SET_SIDEBAR_APPS_UI_FLAG, { isUpdating: true });
    try {
      const response = await SidebarAppsAPI.update(id, updateObj);
      commit(types.EDIT_SIDEBAR_APP, response.data);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_SIDEBAR_APPS_UI_FLAG, { isUpdating: false });
    }
  },
  delete: async function deleteApp({ commit }, id) {
    commit(types.SET_SIDEBAR_APPS_UI_FLAG, { isDeleting: true });
    try {
      await SidebarAppsAPI.delete(id);
      commit(types.DELETE_SIDEBAR_APP, id);
    } catch (error) {
      throw new Error(error);
    } finally {
      commit(types.SET_SIDEBAR_APPS_UI_FLAG, { isDeleting: false });
    }
  },
};

export const mutations = {
  [types.SET_SIDEBAR_APPS_UI_FLAG](_state, data) {
    _state.uiFlags = {
      ..._state.uiFlags,
      ...data,
    };
  },

  [types.SET_SIDEBAR_APPS]: MutationHelpers.set,
  [types.CREATE_SIDEBAR_APP]: MutationHelpers.create,
  [types.EDIT_SIDEBAR_APP]: MutationHelpers.update,
  [types.DELETE_SIDEBAR_APP]: MutationHelpers.destroy,
};

export default {
  namespaced: true,
  actions,
  state,
  getters,
  mutations,
};
