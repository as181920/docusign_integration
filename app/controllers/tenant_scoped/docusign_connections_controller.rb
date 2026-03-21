module TenantScoped
  class DocusignConnectionsController < BaseController
    rescue_from Docusign::ConfigurationError, with: :render_docusign_configuration_error

    def show
      connection = TenantDocusignConnection.find_by(tenant: current_tenant)
      render json: serialize_connection(connection)
    end

    def authorize_url
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

    def create
      connection = TenantDocusignConnection.new(connection_params)
      connection.tenant = current_tenant
      connection.connected_by_tenant_user = current_tenant_user
      connection.connected_at ||= Time.current

      if connection.save
        audit!(action: "docusign_connection_created", target: connection)
        render json: serialize_connection(connection), status: :created
      else
        render json: { errors: connection.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def update
      connection = TenantDocusignConnection.find_by!(tenant: current_tenant)
      connection.assign_attributes(connection_params)
      connection.connected_by_tenant_user = current_tenant_user if current_tenant_user

      if connection.save
        audit!(action: "docusign_connection_updated", target: connection)
        render json: serialize_connection(connection)
      else
        render json: { errors: connection.errors.full_messages }, status: :unprocessable_entity
      end
    end

    private

      def connection_params
        params.require(:tenant_docusign_connection).permit(
          :docusign_account_id,
          :docusign_base_uri,
          :oauth_scope,
          :status,
          metadata: {}
        )
      end

      def serialize_connection(connection)
        return { connected: false } if connection.blank?

        {
          id: connection.id,
          connected: connection.active?,
          status: connection.status,
          docusign_account_id: connection.docusign_account_id,
          docusign_base_uri: connection.docusign_base_uri,
          oauth_scope: connection.oauth_scope,
          token_expires_at: connection.token_expires_at,
          connected_at: connection.connected_at,
          metadata: connection.metadata
        }
      end

      def render_docusign_configuration_error(exception)
        render json: { error: exception.message }, status: :unprocessable_entity
      end
  end
end
