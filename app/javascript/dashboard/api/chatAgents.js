import ApiClient from './ApiClient';

class ChatAgentsAPI extends ApiClient {
  constructor() {
    super('chat_agents', { accountScoped: true });
  }

  getMessages(agentId) {
    return axios.get(`${this.url}/${agentId}/messages`);
  }

  sendMessage(agentId, message) {
    return axios.post(`${this.url}/${agentId}/messages`, { message });
  }

  clearMessages(agentId) {
    return axios.delete(`${this.url}/${agentId}/messages`);
  }
}

export default new ChatAgentsAPI();
