module Tenant
  module IntegrationGuides
    class FeishusController < BaseController
      def show
        @feishu_callback_url = integrations_feishu_callback_url
        @feishu_events_url = integrations_feishu_events_url
        @access_entry_url = tenant_dashboard_url(tenant_uid: current_tenant.uid)

        render "tenant/integration_guides/feishu"
      end
    end
  end
end
