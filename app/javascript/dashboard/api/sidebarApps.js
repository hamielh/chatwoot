import ApiClient from './ApiClient';

class SidebarAppsAPI extends ApiClient {
  constructor() {
    super('sidebar_apps', { accountScoped: true });
  }
}

export default new SidebarAppsAPI();
