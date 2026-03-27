module Tenant
  module IntegrationGuides
    class FeishusController < BaseController
      def show
        assign_feishu_guide_data

        render "tenant/integration_guides/feishu"
      end

      private

        def assign_feishu_guide_data
          @editing_feishu_configuration = false
          @feishu_enterprise = FeishuEnterprise.find_or_initialize_by(tenant: current_tenant)
          @feishu_entry_url = integrations_feishu_entry_url(tenant_uid: current_tenant.uid)
          @feishu_callback_url = integrations_feishu_callback_url
          @feishu_events_url = integrations_feishu_events_url
          @feishu_oauth_authorize_path = tenant_integration_guides_feishu_oauth_authorization_path(tenant_uid: current_tenant.uid)
          @feishu_app_configuration_path = tenant_integration_guides_feishu_app_configuration_path(tenant_uid: current_tenant.uid)
          @feishu_app_configuration_edit_path = edit_tenant_integration_guides_feishu_app_configuration_path(tenant_uid: current_tenant.uid)
          @feishu_connection_test_path = tenant_integration_guides_feishu_connection_test_path(tenant_uid: current_tenant.uid)
        end
    end
  end
end
