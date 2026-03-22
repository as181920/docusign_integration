module Tenant
  class IntegrationGuidesController < BaseController
    def feishu
      @feishu_callback_url = integrations_feishu_callback_url
      @feishu_events_url = integrations_feishu_events_url
      @merchant_login_url = tenant_auth.iam_sign_in_url(
        tenant_uid: current_tenant.uid,
        redirect_url: tenant_dashboard_path(tenant_uid: current_tenant.uid)
      )
    end

    def sap; end

    def fanwei; end
  end
end
