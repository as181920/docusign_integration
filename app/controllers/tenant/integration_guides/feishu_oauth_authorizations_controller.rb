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

        authorize_url = ::Feishu::OauthClient.new.authorization_url(state: state)

        audit(
          action: "feishu_oauth_authorization_requested",
          target: current_tenant,
          data: {
            tenant_uid: current_tenant.uid,
            tenant_user_id: current_user&.id
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
