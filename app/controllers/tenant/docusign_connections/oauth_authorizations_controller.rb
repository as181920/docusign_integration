module Tenant
  module DocusignConnections
    class OauthAuthorizationsController < BaseController
      rescue_from Docusign::ConfigurationError, with: :render_docusign_configuration_error

      def create
        connection = TenantDocusignConnection.find_by(tenant: current_tenant)
        scope = params[:scope].presence || connection&.oauth_scope.presence || "signature"
        state = Docusign::OauthState.generate(
          tenant_uid: current_tenant.uid,
          tenant_user_id: current_tenant_user&.id,
          return_to: params[:return_to].presence
        )

        authorize_url = Docusign::OauthClient.new.authorization_url(state:, scope:)
        audit!(
          action: "docusign_oauth_authorize_url_requested",
          target: connection,
          data: { scope: scope, tenant_uid: current_tenant.uid }
        )

        render json: {
          authorize_url: authorize_url,
          scope: scope,
          state: state,
          expires_in_seconds: 15.minutes.to_i
        }
      end

      private

        def render_docusign_configuration_error(exception)
          render json: { error: exception.message }, status: :unprocessable_entity
        end
    end
  end
end
