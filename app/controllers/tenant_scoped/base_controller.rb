module TenantScoped
  class BaseController < ApplicationController
    before_action :load_current_tenant

    private

      def load_current_tenant
        @current_tenant = TenantAuth::Tenant.find_by!(uid: params[:tenant_uid])
      end

      def current_tenant_user
        tenant_user_id = session[:tenant_user_id]
        return nil if tenant_user_id.blank?

        TenantAuth::User.find_by(id: tenant_user_id, tenant_id: current_tenant.id)
      end
  end
end
