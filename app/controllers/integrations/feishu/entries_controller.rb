module Integrations
  module Feishu
    class EntriesController < ApplicationController
      layout "easy_style/common"

      rescue_from ActionController::ParameterMissing, with: :render_bad_request
      rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
      rescue_from ::Feishu::ConfigurationError, with: :render_configuration_error

      def show
        skip_authorization

        tenant = resolve_tenant
        @current_tenant = tenant

        if current_user.present? && current_user.tenant_id == tenant.id
          return redirect_to tenant_dashboard_path(tenant_uid: tenant.uid)
        end

        state = ::Feishu::OauthState.generate(
          tenant_uid: tenant.uid,
          return_to: tenant_dashboard_path(tenant_uid: tenant.uid)
        )
        authorize_url = ::Feishu::OauthClient.new.authorization_url(state: state)

        audit(
          tenant: tenant,
          actor: current_user,
          action: "feishu_entry_redirected_to_oauth",
          target: tenant,
          data: {
            tenant_uid: tenant.uid,
            tenant_key: normalized_tenant_key
          }
        )

        redirect_to authorize_url, allow_other_host: true
      end

      private

        def resolve_tenant
          tenant_uid = params[:tenant_uid].presence
          tenant_key = normalized_tenant_key

          if tenant_uid.present?
            tenant = TenantAuth::Tenant.find_by!(uid: tenant_uid)
            verify_enterprise_tenant_key!(tenant: tenant, tenant_key: tenant_key) if tenant_key.present?
            return tenant
          end

          return FeishuEnterprise.find_by!(tenant_key: tenant_key).tenant if tenant_key.present?

          raise ActionController::ParameterMissing, :tenant_uid
        end

        def verify_enterprise_tenant_key!(tenant:, tenant_key:)
          enterprise = FeishuEnterprise.find_by(tenant: tenant)
          return if enterprise.blank? || enterprise.tenant_key.blank?
          return if enterprise.tenant_key == tenant_key

          raise ActiveRecord::RecordNotFound, "tenant not found"
        end

        def normalized_tenant_key
          params[:tenant_key].presence || params[:tenantKey].presence
        end

        def current_user
          tenant_user_id = session[:tnt_user_id]
          return nil if tenant_user_id.blank?

          if defined?(@current_user) && @current_user.present? && @current_user.id == tenant_user_id
            return @current_user
          end

          @current_user = TenantAuth::User.find_by(id: tenant_user_id)
        end

        def render_bad_request(exception)
          render_tenant_resolution_error(
            exception: exception,
            status: :bad_request,
            title: I18n.t("integrations.feishu.entries.resolve_tenant.bad_request_title"),
            message: I18n.t("integrations.feishu.entries.resolve_tenant.bad_request_message")
          )
        end

        def render_not_found(exception)
          render_tenant_resolution_error(
            exception: exception,
            status: :not_found,
            title: I18n.t("integrations.feishu.entries.resolve_tenant.not_found_title"),
            message: I18n.t("integrations.feishu.entries.resolve_tenant.not_found_message")
          )
        end

        def render_configuration_error(exception)
          render_error(status: :unprocessable_entity, message: exception.message)
        end

        def render_tenant_resolution_error(exception:, status:, title:, message:)
          respond_to do |format|
            format.html do
              @entry_error_title = title
              @entry_error_message = message
              @entry_error_details = exception.message
              @entry_error_status = status
              @submitted_tenant_uid = params[:tenant_uid].to_s
              @submitted_tenant_key = normalized_tenant_key
              render "integrations/feishu/entries/resolve_tenant", status: status
            end
            format.json { render json: { error: exception.message }, status: status }
          end
        end

        def render_error(status:, message:)
          respond_to do |format|
            format.html { render plain: message, status: status }
            format.json { render json: { error: message }, status: status }
          end
        end
    end
  end
end
