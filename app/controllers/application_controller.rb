class ApplicationController < ActionController::Base
  include Pundit::Authorization
  include AuditLoggable
  include LocaleGuard

  helper EasyStyle::BrowserHelper if defined?(EasyStyle::BrowserHelper)
  helper EasyStyle::SidebarHelper if defined?(EasyStyle::SidebarHelper)
  helper EasyStyle::ApplicationHelper if defined?(EasyStyle::ApplicationHelper)
  helper_method :current_tenant, :current_user if respond_to?(:helper_method)

  protect_from_forgery with: :exception

  rescue_from Pundit::NotAuthorizedError, with: :render_forbidden

  private

    def current_tenant
      @current_tenant
    end

    def current_user
      nil
    end

    def default_url_options
      locale_value = I18n.locale.to_s
      default_locale_value = I18n.default_locale.to_s
      return {} unless @locale_explicitly_requested
      return {} if locale_value == default_locale_value

      { locale: locale_value }
    end

    def policy_scope_records(scope)
      policy_scope(scope)
    rescue Pundit::NotDefinedError
      scope
    end

    def pagination_per(default: 20, max: 100)
      requested = params[:per].to_i
      requested = default if requested <= 0
      requested = max if requested > max
      requested
    end

    def render_forbidden
      render json: { error: I18n.t("errors.forbidden") }, status: :forbidden
    end
end
