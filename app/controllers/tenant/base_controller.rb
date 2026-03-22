module Tenant
  class BaseController < ApplicationController
    layout "tenant/admin"

    before_action :load_current_tenant
    before_action :authenticate_tenant_user!

    private

      def load_current_tenant
        @current_tenant = TenantAuth::Tenant.find_by!(uid: params[:tenant_uid])
      end

      def authenticate_tenant_user!
        return if current_tenant_user.present?

        respond_to do |format|
          format.html do
            redirect_to tenant_auth.iam_sign_in_path(
              tenant_uid: current_tenant.uid,
              redirect_url: request.fullpath
            )
          end
          format.json { render json: { error: "unauthorized" }, status: :unauthorized }
          format.any { head :unauthorized }
        end
      end

      def current_tenant_user
        return @current_tenant_user if defined?(@current_tenant_user)

        tenant_user_id = session[:tnt_user_id] || session[:tenant_user_id]
        return @current_tenant_user = nil if tenant_user_id.blank?

        @current_tenant_user = TenantAuth::User.find_by(id: tenant_user_id, tenant_id: current_tenant.id)
      end
  end
end
