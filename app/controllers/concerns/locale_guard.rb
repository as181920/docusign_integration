module LocaleGuard
  extend ActiveSupport::Concern

  included do
    around_action :switch_locale, :switch_time_zone
  end

  private

    def switch_locale(&block)
      @locale_explicitly_requested = params[:locale].present?
      I18n.with_locale(resolved_locale, &block)
    ensure
      @locale_explicitly_requested = false
    end

    def switch_time_zone(&block)
      Time.use_zone(resolved_time_zone, &block)
    end

    def resolved_locale
      requested_locale = params[:locale].presence || locale_guard_user_locale || extract_locale_from_header
      normalized_locale(requested_locale)
    end

    def locale_guard_user_locale
      user = locale_guard_user
      return if user.blank? || !user.respond_to?(:locale)

      user.locale
    end

    def resolved_time_zone
      user_time_zone = locale_guard_user_time_zone
      return user_time_zone if user_time_zone.present?

      detected_time_zone
    end

    def locale_guard_user_time_zone
      user = locale_guard_user
      return if user.blank? || !user.respond_to?(:time_zone)

      user_time_zone = user.time_zone.to_s.strip
      return if user_time_zone.blank?

      ActiveSupport::TimeZone[user_time_zone]&.name
    end

    def locale_guard_user
      return current_user if respond_to?(:current_user, true)

      nil
    rescue StandardError
      nil
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

    def detected_time_zone
      detected_time_zone = TenantAuth::RequestLocaleService.new(request).detect_time_zone.to_s.strip
      resolved_time_zone = detected_time_zone.present? ? ActiveSupport::TimeZone[detected_time_zone] : nil
      resolved_time_zone&.name || Rails.application.config.time_zone
    rescue StandardError
      Rails.application.config.time_zone
    end

    def normalized_locale(locale)
      locale_str = locale.to_s
      available_locales = I18n.available_locales.map(&:to_s)
      return locale_str if available_locales.include?(locale_str)

      locale_str.split("-").first.presence_in(available_locales) || I18n.default_locale
    end
end
