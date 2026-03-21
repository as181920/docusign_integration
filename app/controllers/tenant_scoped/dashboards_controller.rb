module TenantScoped
  class DashboardsController < BaseController
    def show
      render json: {
        tenant_uid: current_tenant.uid,
        tenant_name: current_tenant.name,
        message: "docusign integration service ready"
      }
    end
  end
end
