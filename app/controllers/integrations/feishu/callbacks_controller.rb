module Integrations
  module Feishu
    class CallbacksController < ApplicationController
      layout :callback_layout

      rescue_from ::Feishu::ConfigurationError, ::Feishu::ApiError, ::Feishu::Error, with: :render_feishu_error
      rescue_from ::Feishu::OauthStateError, with: :render_invalid_state
      rescue_from ActionController::ParameterMissing, with: :render_bad_request
      rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

      def show
        skip_authorization
        if params[:error].present?
          return render_authorization_failure(
            details: params[:error_description].presence || params[:error]
          )
        end

        context = resolve_oauth_context
        tenant = context.fetch(:tenant)
        state_payload = context[:state_payload]
        @current_tenant = tenant

        oauth_user_info = fetch_oauth_user_info
        incoming_tenant_key = extract_tenant_key(oauth_user_info: oauth_user_info)
        tenant_name = extract_tenant_name(oauth_user_info: oauth_user_info)
        enterprise_payload = build_enterprise_payload(
          incoming_tenant_key: incoming_tenant_key,
          tenant_name: tenant_name,
          state_payload: state_payload
        )

        enterprise = upsert_enterprise(
          tenant: tenant,
          incoming_tenant_key: incoming_tenant_key,
          tenant_name: tenant_name,
          raw_payload: enterprise_payload
        )

        identity = provision_identity_if_possible(tenant: tenant, oauth_user_info: oauth_user_info)
        bind_session(identity)

        return_to = normalized_return_to(
          value: state_payload&.dig("return_to"),
          tenant_uid: tenant.uid
        )

        audit(
          tenant: tenant,
          actor: identity&.tenant_user,
          action: "feishu_callback_received",
          target: enterprise,
          data: {
            tenant_key: enterprise.tenant_key,
            return_to: return_to,
            identity_id: identity&.id,
            user_id: identity&.user_id,
            tenant_user_id: identity&.tenant_user_id
          }
        )

        respond_to do |format|
          format.html do
            assign_callback_view_state(
              status: :success,
              title: I18n.t("integrations.feishu.callbacks.result.success_title"),
              message: I18n.t("integrations.feishu.callbacks.result.success_message"),
              tenant: tenant,
              enterprise: enterprise,
              identity: identity,
              return_to: return_to
            )
            render :show
          end
          format.json do
            render json: {
              message: t("integrations.feishu.callbacks.messages.received"),
              tenant_uid: tenant.uid,
              tenant_key: enterprise.tenant_key,
              return_to: return_to,
              user_id: identity&.user_id,
              tenant_user_id: identity&.tenant_user_id
            }
          end
        end
      rescue ActiveRecord::RecordInvalid => e
        respond_to do |format|
          format.html do
            assign_callback_view_state(
              status: :error,
              title: I18n.t("integrations.feishu.callbacks.result.failure_title"),
              message: e.record.errors.full_messages.to_sentence
            )
            render :show, status: :unprocessable_entity
          end
          format.json { render json: { error: e.record.errors.full_messages.to_sentence }, status: :unprocessable_entity }
        end
      end

      private

        def resolve_oauth_context
          if params[:state].present?
            state_payload = ::Feishu::OauthState.verify(params[:state])
            tenant_uid = state_payload.fetch("tenant_uid")
            tenant = TenantAuth::Tenant.find_by!(uid: tenant_uid)
            return { tenant: tenant, state_payload: state_payload }
          end

          tenant = TenantAuth::Tenant.find_by!(uid: params.require(:tenant_uid))
          { tenant: tenant, state_payload: nil }
        end

        def fetch_oauth_user_info
          return params.to_unsafe_h if params[:code].blank?

          oauth_client = ::Feishu::OauthClient.new
          token_info = oauth_client.exchange_code(code: params.require(:code))
          oauth_client.user_info(access_token: token_info.fetch("access_token")).stringify_keys
        end

        def upsert_enterprise(tenant:, incoming_tenant_key:, tenant_name:, raw_payload:)
          enterprise = FeishuEnterprise.find_or_initialize_by(tenant: tenant)

          if tenant_key_conflict?(enterprise: enterprise, incoming_tenant_key: incoming_tenant_key)
            raise ::Feishu::Error, t("integrations.feishu.callbacks.errors.tenant_key_mismatch")
          end

          enterprise.tenant_key = incoming_tenant_key if incoming_tenant_key.present?
          enterprise.app_id = ENV.fetch("feishu_app_id", nil)
          enterprise.name = tenant_name if tenant_name.present?
          enterprise.raw_payload = raw_payload
          enterprise.save!

          enterprise
        end

        def tenant_key_conflict?(enterprise:, incoming_tenant_key:)
          enterprise.persisted? && enterprise.tenant_key.present? && incoming_tenant_key.present? && enterprise.tenant_key != incoming_tenant_key
        end

        def extract_tenant_key(oauth_user_info:)
          params[:tenant_key].presence || params[:tenantKey].presence || oauth_user_info["tenant_key"].presence
        end

        def extract_tenant_name(oauth_user_info:)
          params[:tenant_name].presence || oauth_user_info["tenant_name"].presence
        end

        def build_enterprise_payload(incoming_tenant_key:, tenant_name:, state_payload:)
          {
            "source" => "feishu_oauth_callback",
            "tenant_key" => incoming_tenant_key,
            "tenant_name" => tenant_name,
            "state_tenant_uid" => state_payload&.dig("tenant_uid"),
            "state_return_to" => state_payload&.dig("return_to")
          }.compact
        end

        def provision_identity_if_possible(tenant:, oauth_user_info:)
          auth_info = oauth_user_info.slice("union_id", "open_id", "name", "avatar_url")
          return nil if auth_info["union_id"].blank? && auth_info["open_id"].blank?

          ::Feishu::UserProvisioningService.call(tenant: tenant, auth_info: auth_info)
        end

        def bind_session(identity)
          return if identity.blank?

          session[:tenant_user_id] = identity.tenant_user_id if identity.tenant_user_id.present?
          session[:user_id] = identity.user_id if identity.user_id.present?
        end

        def normalized_return_to(value:, tenant_uid:)
          fallback_path = tenant_dashboard_path(tenant_uid: tenant_uid)
          candidate = value.to_s.strip
          return fallback_path if candidate.blank?
          return fallback_path unless candidate.start_with?("/")

          candidate
        end

        def assign_callback_view_state(status:, title:, message:, tenant: nil, enterprise: nil, identity: nil, return_to: nil)
          @callback_status = status
          @callback_title = title
          @callback_message = message
          @tenant = tenant
          @enterprise = enterprise
          @identity = identity
          @return_to = return_to
          @current_tenant = tenant if tenant.present?
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

        def render_authorization_failure(details:)
          respond_to do |format|
            format.html do
              assign_callback_view_state(
                status: :error,
                title: I18n.t("integrations.feishu.callbacks.result.failure_title"),
                message: details
              )
              render :show, status: :unprocessable_entity
            end
            format.json do
              render json: {
                error: "feishu_authorization_failed",
                details: details
              }, status: :unprocessable_entity
            end
          end
        end

        def render_invalid_state(exception)
          respond_to do |format|
            format.html do
              assign_callback_view_state(
                status: :error,
                title: I18n.t("integrations.feishu.callbacks.result.invalid_state_title"),
                message: exception.message
              )
              render :show, status: :unauthorized
            end
            format.json { render json: { error: exception.message }, status: :unauthorized }
          end
        end

        def render_feishu_error(exception)
          respond_to do |format|
            format.html do
              assign_callback_view_state(
                status: :error,
                title: I18n.t("integrations.feishu.callbacks.result.failure_title"),
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
                title: I18n.t("integrations.feishu.callbacks.result.bad_request_title"),
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
                title: I18n.t("integrations.feishu.callbacks.result.not_found_title"),
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
