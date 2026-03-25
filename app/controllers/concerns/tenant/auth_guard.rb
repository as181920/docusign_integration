module Tenant
  module AuthGuard
    extend ActiveSupport::Concern

    included do
      before_action :load_current_tenant
      before_action :authenticate_tenant_user
      before_action :authorize_current_tenant, except: :index
    end

    private

      def load_current_tenant
        @current_tenant = TenantAuth::Tenant.find_by!(uid: params[:tenant_uid])
      end

      def authenticate_tenant_user
        return if current_user.present?

        respond_to do |format|
          format.html do
            redirect_to tenant_auth.iam_sign_in_path(
              tenant_uid: current_tenant.uid,
              redirect_url: request.fullpath
            )
          end
          format.json { render json: { error: I18n.t("errors.unauthorized") }, status: :unauthorized }
          format.any { head :unauthorized }
        end
      end

      def authorize_current_tenant
        authorize current_tenant, policy_class: ApplicationPolicy
      end

      def current_user
        tenant_user_id = session[:tnt_user_id]
        return @current_user = nil if tenant_user_id.blank?

        if current_tenant.blank?
          return @current_user = TenantAuth::User.find_by(id: tenant_user_id)
        end

        if defined?(@current_user) && @current_user.present? &&
           @current_user.id == tenant_user_id && @current_user.tenant_id == current_tenant.id
          return @current_user
        end

        @current_user = TenantAuth::User.find_by(id: tenant_user_id, tenant_id: current_tenant.id)
      end
  end
end
