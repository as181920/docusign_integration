module Tenant
  module IntegrationGuides
    class FeishuOauthAuthorizationsController < BaseController
      rescue_from ::Feishu::ConfigurationError, with: :handle_configuration_error

      def create
        state = ::Feishu::OauthState.generate(
          tenant_uid: current_tenant.uid,
          tenant_user_id: current_user&.id,
          return_to: tenant_dashboard_path(tenant_uid: current_tenant.uid)
        )

        enterprise = FeishuEnterprise.find_by(tenant: current_tenant)
        oauth_client = ::Feishu::OauthClient.for_enterprise!(
          enterprise: enterprise,
          redirect_uri_fallback: integrations_feishu_callback_url
        )
        authorize_url = oauth_client.authorization_url(state: state)

        audit(
          action: "feishu_oauth_authorization_requested",
          target: enterprise || current_tenant,
          data: {
            tenant_uid: current_tenant.uid,
            tenant_user_id: current_user&.id,
            app_id: enterprise&.app_id
          }
        )

        redirect_to authorize_url, allow_other_host: true
      end

      private

        def handle_configuration_error(exception)
          redirect_to tenant_integration_guides_feishu_path(tenant_uid: current_tenant.uid), alert: exception.message
        end
    end
  end
end
