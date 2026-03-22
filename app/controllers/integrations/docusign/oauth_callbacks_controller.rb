module Integrations
  module Docusign
    class OauthCallbacksController < ApplicationController
      layout :callback_layout

      rescue_from ::Docusign::OauthStateError, with: :render_invalid_state
      rescue_from ::Docusign::ConfigurationError, ::Docusign::ApiError, with: :render_docusign_error
      rescue_from ActionController::ParameterMissing, with: :render_bad_request
      rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

      def show
        skip_authorization
        if params[:error].present?
          return render_authorization_failure(
            details: params[:error_description].presence || params[:error]
          )
        end

        state_payload = ::Docusign::OauthState.verify(params.require(:state))
        tenant = TenantAuth::Tenant.find_by!(uid: state_payload.fetch("tenant_uid"))
        tenant_user = resolve_tenant_user(tenant:, tenant_user_id: state_payload["tenant_user_id"])
        @current_tenant = tenant

        oauth_client = ::Docusign::OauthClient.new
        token_info = oauth_client.exchange_code(code: params.require(:code))
        user_info = oauth_client.user_info(access_token: token_info.fetch("access_token"))

        account = select_account(
          user_info: user_info,
          preferred_account_id: params[:account_id].presence || ENV.fetch("docusign_account_id", nil)
        )

        connection = TenantDocusignConnection.find_or_initialize_by(tenant: tenant)
        connection.assign_attributes(
          docusign_account_id: account.fetch("account_id"),
          docusign_base_uri: normalize_base_uri(account["base_uri"]),
          oauth_scope: token_info["scope"].presence || connection.oauth_scope.presence || "signature",
          access_token: token_info.fetch("access_token"),
          refresh_token: token_info["refresh_token"].presence || connection.refresh_token,
          token_expires_at: token_expired_at(token_info),
          connected_at: connection.connected_at || Time.current,
          status: :active
        )
        connection.connected_by_tenant_user = tenant_user if tenant_user
        connection.metadata = connection.metadata.to_h.merge(
          "oauth_user_info" => {
            "sub" => user_info["sub"],
            "name" => user_info["name"],
            "email" => user_info["email"],
            "account_id" => account["account_id"],
            "account_name" => account["account_name"],
            "is_default" => account["is_default"]
          },
          "oauth_callback" => {
            "state_issued_at" => state_payload["issued_at"],
            "processed_at" => Time.current.iso8601
          }
        )
        connection.save!

        return_to = normalized_return_to(
          value: state_payload["return_to"],
          tenant_uid: tenant.uid
        )

        audit(
          tenant: tenant,
          actor: tenant_user,
          action: "docusign_oauth_connected",
          target: connection,
          data: {
            docusign_account_id: connection.docusign_account_id,
            return_to: return_to
          }
        )

        respond_to do |format|
          format.html do
            assign_callback_view_state(
              status: :success,
              title: I18n.t("integrations.docusign.oauth_callbacks.result.success_title"),
              message: I18n.t("integrations.docusign.oauth_callbacks.result.success_message"),
              tenant: tenant,
              connection: connection,
              return_to: return_to
            )
            render :show
          end
          format.json do
            render json: {
              message: I18n.t("integrations.docusign.oauth_callbacks.messages.connected"),
              tenant_uid: tenant.uid,
              return_to: return_to,
              connection: serialized_connection(connection)
            }
          end
        end
      rescue ActiveRecord::RecordInvalid => e
        respond_to do |format|
          format.html do
            assign_callback_view_state(
              status: :error,
              title: I18n.t("integrations.docusign.oauth_callbacks.result.failure_title"),
              message: e.record.errors.full_messages.to_sentence
            )
            render :show, status: :unprocessable_entity
          end
          format.json { render json: { error: e.record.errors.full_messages.to_sentence }, status: :unprocessable_entity }
        end
      end

      private

        def assign_callback_view_state(status:, title:, message:, tenant: nil, connection: nil, return_to: nil)
          @callback_status = status
          @callback_title = title
          @callback_message = message
          @tenant = tenant
          @connection = connection
          @return_to = return_to
          @current_tenant = tenant if tenant.present?
        end

        def render_authorization_failure(details:)
          respond_to do |format|
            format.html do
              assign_callback_view_state(
                status: :error,
                title: I18n.t("integrations.docusign.oauth_callbacks.result.failure_title"),
                message: details
              )
              render :show, status: :unprocessable_entity
            end
            format.json do
              render json: {
                error: "docusign_authorization_failed",
                details: details
              }, status: :unprocessable_entity
            end
          end
        end

        def normalized_return_to(value:, tenant_uid:)
          fallback_path = tenant_docusign_connection_path(tenant_uid: tenant_uid)
          candidate = value.to_s.strip
          return fallback_path if candidate.blank?
          return fallback_path unless candidate.start_with?("/")

          candidate
        end

        def current_user
  return nil if current_tenant.blank?

  tenant_user_id = session[:tnt_user_id] || session[:tenant_user_id]
  return nil if tenant_user_id.blank?

  if defined?(@current_user) && @current_user.present? &&
     @current_user.id == tenant_user_id && @current_user.tenant_id == current_tenant.id
    return @current_user
  end

  @current_user = TenantAuth::User.find_by(id: tenant_user_id, tenant_id: current_tenant.id)
        end

        def callback_layout
          current_user.present? ? "tenant/admin" : "easy_style/common"
        end

        def resolve_tenant_user(tenant:, tenant_user_id:)
          return nil if tenant_user_id.blank?

          TenantAuth::User.find_by(id: tenant_user_id, tenant_id: tenant.id)
        end

        def token_expired_at(token_info)
          expires_in = token_info["expires_in"].to_i
          return 2.hours.from_now if expires_in <= 0

          Time.current + expires_in.seconds
        end

        def select_account(user_info:, preferred_account_id:)
          accounts = Array(user_info["accounts"]).map { |account| normalize_account(account) }
          raise ::Docusign::ApiError, "no docusign accounts available in userinfo" if accounts.blank?

          selected = if preferred_account_id.present?
            accounts.find { |account| account["account_id"] == preferred_account_id }
          end

          selected ||= accounts.find { |account| account["is_default"] }
          selected ||= accounts.first
          selected
        end

        def normalize_account(account)
          {
            "account_id" => account["account_id"] || account["accountId"],
            "account_name" => account["account_name"] || account["accountName"],
            "is_default" => account["is_default"] || account["isDefault"] || false,
            "base_uri" => account["base_uri"] || account["baseUri"]
          }
        end

        def normalize_base_uri(base_uri)
          value = base_uri.to_s.sub(%r{/$}, "")
          value = ENV.fetch("docusign_base_uri", "") if value.blank?
          value = value.sub(%r{/$}, "")

          return value if value.end_with?("/restapi")

          "#{value}/restapi"
        end

        def serialized_connection(connection)
          {
            id: connection.id,
            status: connection.status,
            docusign_account_id: connection.docusign_account_id,
            docusign_base_uri: connection.docusign_base_uri,
            oauth_scope: connection.oauth_scope,
            token_expires_at: connection.token_expires_at,
            connected_at: connection.connected_at,
            metadata: connection.metadata
          }
        end

        def render_invalid_state(exception)
          respond_to do |format|
            format.html do
              assign_callback_view_state(
                status: :error,
                title: I18n.t("integrations.docusign.oauth_callbacks.result.invalid_state_title"),
                message: exception.message
              )
              render :show, status: :unauthorized
            end
            format.json { render json: { error: exception.message }, status: :unauthorized }
          end
        end

        def render_docusign_error(exception)
          respond_to do |format|
            format.html do
              assign_callback_view_state(
                status: :error,
                title: I18n.t("integrations.docusign.oauth_callbacks.result.failure_title"),
                message: exception.message
              )
              render :show, status: :unprocessable_entity
            end
            format.json { render json: { error: exception.message }, status: :unprocessable_entity }
          end
        end

        def render_bad_request(exception)
          respond_to do |format|
            format.html do
              assign_callback_view_state(
                status: :error,
                title: I18n.t("integrations.docusign.oauth_callbacks.result.bad_request_title"),
                message: exception.message
              )
              render :show, status: :bad_request
            end
            format.json { render json: { error: exception.message }, status: :bad_request }
          end
        end

        def render_not_found(exception)
          respond_to do |format|
            format.html do
              assign_callback_view_state(
                status: :error,
                title: I18n.t("integrations.docusign.oauth_callbacks.result.not_found_title"),
                message: exception.message
              )
              render :show, status: :not_found
            end
            format.json { render json: { error: exception.message }, status: :not_found }
          end
        end
    end
  end
end
