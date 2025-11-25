export const state = {
  isOpen: false,
};

export const getters = {
  isOpen: _state => _state.isOpen,
};

export const actions = {
  toggle({ commit, state: _state }) {
    commit('SET_OPEN', !_state.isOpen);
  },
  open({ commit }) {
    commit('SET_OPEN', true);
  },
  close({ commit }) {
    commit('SET_OPEN', false);
  },
};

export const mutations = {
  SET_OPEN(_state, value) {
    _state.isOpen = value;
  },
};

export default {
  namespaced: true,
  state,
  getters,
  actions,
  mutations,
};
