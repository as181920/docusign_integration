module Tenant
  module IntegrationGuides
    class FeishusController < BaseController
      def show
        @feishu_callback_url = ENV.fetch("feishu_oauth_redirect_uri", nil).presence || integrations_feishu_callback_url
        @feishu_events_url = integrations_feishu_events_url
        @feishu_entry_url = integrations_feishu_entry_url(tenant_uid: current_tenant.uid)
        @feishu_oauth_authorize_path = tenant_integration_guides_feishu_oauth_authorization_path(tenant_uid: current_tenant.uid)
        @access_entry_url = tenant_dashboard_url(tenant_uid: current_tenant.uid)

        render "tenant/integration_guides/feishu"
      end
    end
  end
end
