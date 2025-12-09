import { frontendURL } from '../../../helper/URLHelper';
import SidebarAppView from './Index.vue';

export default {
  routes: [
    {
      path: frontendURL('accounts/:accountId/apps/:appId'),
      name: 'sidebar_app_view',
      component: SidebarAppView,
      meta: {
        permissions: ['administrator', 'agent'],
      },
    },
  ],
};
