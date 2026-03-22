class WelcomeController < ApplicationController
  layout "easy_style/common"

  def show
    skip_authorization
    @demo_tenant_uid = ENV.fetch("app_demo_tenant_uid", "demo").presence || "demo"

    @signed_in_tenant_user = TenantAuth::User.includes(:tenant).find_by(id: session[:tnt_user_id] || session[:tenant_user_id])
    @dashboard_tenant_uid = @signed_in_tenant_user&.tenant&.uid.presence || @demo_tenant_uid
  end
end
