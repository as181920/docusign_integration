module Tenant
  class DocusignConnectionsController < BaseController
    def show
      connection = TenantDocusignConnection.find_by(tenant: current_tenant)
      render json: serialize_connection(connection)
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
  end
end
