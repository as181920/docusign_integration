module Tenant
  class DocusignConnectionsController < BaseController
    before_action :set_connection, only: %i[show new edit update]

    def show
      @authorize_url = nil
      prepare_scope_options(scope_source: @connection&.oauth_scope)

      respond_to do |format|
        format.html
        format.json { render json: serialize_connection(@connection) }
      end
    end

    def new
      if @connection.present?
        redirect_to edit_tenant_docusign_connection_path(tenant_uid: current_tenant.uid)
        return
      end

      @connection_form = TenantDocusignConnection.new(status: :active, oauth_scope: "signature")
      prepare_scope_options(scope_source: @connection_form.oauth_scope)
    end

    def edit
      if @connection.blank?
        redirect_to new_tenant_docusign_connection_path(tenant_uid: current_tenant.uid)
        return
      end

      @connection_form = @connection
      prepare_scope_options(scope_source: @connection_form.oauth_scope)
    end

    def create
      @connection_form = TenantDocusignConnection.new(connection_params)
      @connection_form.tenant = current_tenant
      @connection_form.connected_by_tenant_user = current_user
      @connection_form.connected_at ||= Time.current

      if @connection_form.save
        audit(action: "docusign_connection_created", target: @connection_form)
        respond_to do |format|
          format.html { redirect_to tenant_docusign_connection_path(tenant_uid: current_tenant.uid), notice: t("tenant.docusign_connections.notices.created") }
          format.json { render json: serialize_connection(@connection_form), status: :created }
        end
      else
        prepare_scope_options(scope_source: @connection_form.oauth_scope)

        respond_to do |format|
          format.html do
            flash.now[:alert] = @connection_form.errors.full_messages.to_sentence
            render :new, status: :unprocessable_entity
          end
          format.json { render json: { errors: @connection_form.errors.full_messages }, status: :unprocessable_entity }
        end
      end
    end

    def update
      raise ActiveRecord::RecordNotFound, "DocuSign connection not found" if @connection.blank?

      @connection_form = @connection
      @connection_form.assign_attributes(connection_params)
      @connection_form.connected_by_tenant_user = current_user if current_user

      if @connection_form.save
        audit(action: "docusign_connection_updated", target: @connection_form)
        respond_to do |format|
          format.html { redirect_to tenant_docusign_connection_path(tenant_uid: current_tenant.uid), notice: t("tenant.docusign_connections.notices.updated") }
          format.json { render json: serialize_connection(@connection_form) }
        end
      else
        prepare_scope_options(scope_source: @connection_form.oauth_scope)

        respond_to do |format|
          format.html do
            flash.now[:alert] = @connection_form.errors.full_messages.to_sentence
            render :edit, status: :unprocessable_entity
          end
          format.json { render json: { errors: @connection_form.errors.full_messages }, status: :unprocessable_entity }
        end
      end
    end

    private

      def set_connection
        @connection = TenantDocusignConnection.find_by(tenant: current_tenant)
      end

      def connection_params
        permitted = params.require(:tenant_docusign_connection).permit(
          :docusign_account_id,
          :docusign_base_uri,
          :oauth_scope,
          :status,
          { oauth_scopes: [] },
          metadata: {}
        )

        if @connection.present?
          permitted.delete(:docusign_account_id)
          permitted.delete(:docusign_base_uri)
        end

        if params[:tenant_docusign_connection].key?(:oauth_scopes)
          selected_scopes = normalize_scope_values(permitted.delete(:oauth_scopes))
          permitted[:oauth_scope] = selected_scopes.present? ? selected_scopes.join(" ") : "signature"
        end

        permitted
      end

      def prepare_scope_options(scope_source:)
        @selected_oauth_scopes = normalize_scope_values(scope_source)
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
