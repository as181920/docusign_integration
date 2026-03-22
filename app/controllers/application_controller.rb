class ApplicationController < ActionController::Base
  include Pundit::Authorization
  include AuditLoggable

  helper EasyStyle::BrowserHelper if defined?(EasyStyle::BrowserHelper)
  helper EasyStyle::SidebarHelper if defined?(EasyStyle::SidebarHelper)
  helper EasyStyle::ApplicationHelper if defined?(EasyStyle::ApplicationHelper)
  helper_method :current_tenant, :current_user if respond_to?(:helper_method)

  protect_from_forgery with: :exception

  before_action :set_locale
  around_action :switch_time_zone

  rescue_from Pundit::NotAuthorizedError, with: :render_forbidden

  private

    def current_tenant
      @current_tenant
    end

    def current_user
      nil
    end

    def set_locale
      requested_locale = params[:locale].presence || extract_locale_from_header
      I18n.locale = normalized_locale(requested_locale)
    end

    def switch_time_zone(&block)
      apply_request_time_zone
      yield
    ensure
      Time.zone = Rails.application.config.time_zone
    end

    def default_url_options
      locale_value = I18n.locale.to_s
      default_locale_value = I18n.default_locale.to_s
      return {} if locale_value == default_locale_value

      { locale: locale_value }
    end

    def extract_locale_from_header
      header = request.headers["Accept-Language"].to_s
      return nil if header.blank?

      accepted = header.split(",").map { |item| item.to_s.split(";").first.to_s.strip }.reject(&:blank?)
      available = I18n.available_locales.map(&:to_s)

      accepted.each do |candidate|
        normalized = normalized_locale(candidate)
        return normalized if available.include?(normalized.to_s)
      end

      nil
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

    def apply_request_time_zone
      detected_time_zone = TenantAuth::RequestLocaleService.new(request).detect_time_zone.to_s.strip
      resolved_time_zone = detected_time_zone.present? ? ActiveSupport::TimeZone[detected_time_zone] : nil
      Time.zone = resolved_time_zone&.name || Rails.application.config.time_zone
    rescue StandardError
      Time.zone = Rails.application.config.time_zone
    end

    def normalized_locale(locale)
      locale_str = locale.to_s
      return locale_str if I18n.available_locales.map(&:to_s).include?(locale_str)

      locale_str.split("-").first.presence_in(I18n.available_locales.map(&:to_s)) || I18n.default_locale
    end

    def render_forbidden
      render json: { error: I18n.t("errors.forbidden") }, status: :forbidden
    end
end
