class ApplicationController < ActionController::Base
  include Pundit::Authorization
  include AuditLoggable

  allow_browser versions: :modern
  stale_when_importmap_changes

  rescue_from Pundit::NotAuthorizedError, with: :render_forbidden

  helper_method :current_tenant
  helper_method :current_tenant_user

  private

    def current_tenant
      @current_tenant
    end

    def current_tenant_user
      nil
    end

    def current_audit_user
      current_tenant_user
    end

    def render_forbidden
      render json: { error: "forbidden" }, status: :forbidden
    end
end
