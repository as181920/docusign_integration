module Tenant
  module DocusignConnections
    class OauthAuthorizationsController < BaseController
      rescue_from Docusign::ConfigurationError, with: :render_docusign_configuration_error

      def create
        connection = TenantDocusignConnection.find_by(tenant: current_tenant)
        selected_scopes = normalize_scope_values(params[:scopes])
        scope = selected_scopes.present? ? selected_scopes.join(" ") : params[:scope].presence || connection&.oauth_scope.presence || "signature"
        state = Docusign::OauthState.generate(
          tenant_uid: current_tenant.uid,
          tenant_user_id: current_user&.id,
          return_to: params[:return_to].presence
        )

        authorize_url = Docusign::OauthClient.new.authorization_url(state:, scope:)
        audit(
          action: "docusign_oauth_authorize_url_requested",
          target: connection,
          data: { scope: scope, scopes: selected_scopes, tenant_uid: current_tenant.uid }
        )

        respond_to do |format|
          format.html do
            assign_view_state(connection:, scope:, authorize_url:)
            render "tenant/docusign_connections/show"
          end
          format.json do
            render json: {
              authorize_url: authorize_url,
              scope: scope,
              state: state,
              expires_in_seconds: 15.minutes.to_i
            }
          end
        end
      end

      private

        def assign_view_state(connection:, scope:, authorize_url:)
          @connection = connection
          @connection_form = connection || TenantDocusignConnection.new(status: :active, oauth_scope: scope)
          @connection_readonly = true
          @authorize_url = authorize_url
          @selected_oauth_scopes = normalize_scope_values(scope)
          @selected_oauth_scopes = %w[signature] if @selected_oauth_scopes.blank?
          @oauth_scope_options = (oauth_scope_options + @selected_oauth_scopes).uniq
        end

        def normalize_scope_values(raw_scopes)
          case raw_scopes
          when Array
            raw_scopes
          else
            raw_scopes.to_s.split(/[\s,]+/)
          end.map(&:to_s).map(&:strip).reject(&:blank?).uniq
        end

        def oauth_scope_options
          configured_scopes = ENV.fetch("docusign_oauth_scope_options", "").to_s.split(/[\s,]+/).map(&:strip).reject(&:blank?)
          (%w[signature impersonation extended] + configured_scopes).uniq
        end

        def render_docusign_configuration_error(exception)
          respond_to do |format|
            format.html do
              connection = TenantDocusignConnection.find_by(tenant: current_tenant)
              assign_view_state(connection:, scope: connection&.oauth_scope || "signature", authorize_url: nil)
              flash.now[:alert] = exception.message
              render "tenant/docusign_connections/show", status: :unprocessable_entity
            end
            format.json { render json: { error: exception.message }, status: :unprocessable_entity }
          end
        end
    end
  end
end
