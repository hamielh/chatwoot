/* global axios */
import ApiClient from './ApiClient';

class ScheduledMessagesAPI extends ApiClient {
  constructor() {
    super('conversations', { accountScoped: true });
  }

  get(conversationId) {
    return axios.get(`${this.url}/${conversationId}/scheduled_messages`);
  }

  create(conversationId, { content, scheduledAt, files, isPrivate }) {
    const payload = new FormData();
    if (content) payload.append('content', content);
    payload.append('scheduled_at', scheduledAt);
    payload.append('private', isPrivate || false);
    if (files && files.length) {
      files.forEach(file => payload.append('attachments[]', file));
    }
    return axios.post(
      `${this.url}/${conversationId}/scheduled_messages`,
      payload
    );
  }

  cancel(conversationId, id) {
    return axios.delete(
      `${this.url}/${conversationId}/scheduled_messages/${id}`
    );
  }
}

export default new ScheduledMessagesAPI();
