module Tenant
  class DashboardsController < BaseController
    def show
      respond_to do |format|
        format.html
        format.json do
          render json: {
            tenant_uid: current_tenant.uid,
            tenant_name: current_tenant.name,
            current_user: current_user&.name,
            message: "docusign integration service ready"
          }
        end
      end
    end
  end
end
