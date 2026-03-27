module Tenant
  module IntegrationGuides
    class FeishuConnectionTestsController < BaseController
      rescue_from ::Feishu::ConfigurationError, with: :handle_connection_error
      rescue_from ::Feishu::ApiError, with: :handle_connection_error

      def create
        enterprise = FeishuEnterprise.find_by(tenant: current_tenant)
        oauth_client = ::Feishu::OauthClient.for_enterprise!(
          enterprise: enterprise,
          redirect_uri_fallback: integrations_feishu_callback_url
        )
        oauth_client.test_connection

        audit(
          action: "feishu_connection_tested",
          target: enterprise,
          data: {
            tenant_uid: current_tenant.uid,
            app_id: enterprise&.app_id,
            result: "success"
          }
        )

        redirect_to tenant_integration_guides_feishu_path(tenant_uid: current_tenant.uid),
                    notice: t("tenant.integration_guides.feishu.configuration.connection_test_success")
      end

      private

        def handle_connection_error(exception)
        audit(
          action: "feishu_connection_tested",
          target: current_tenant,
          data: {
            tenant_uid: current_tenant.uid,
            result: "failed",
            error: exception.message
          }
        )
        flush_audit_logs

        redirect_to tenant_integration_guides_feishu_path(tenant_uid: current_tenant.uid),
                    alert: exception.message
      end
    end
  end
end
