module Tenant
  class BaseController < ApplicationController
    layout "tenant/admin"

    before_action :load_current_tenant
    before_action :authenticate_tenant_user
    before_action :authorize_current_tenant, except: :index
    before_action :apply_user_preferences

    private

      def load_current_tenant
        @current_tenant = TenantAuth::Tenant.find_by!(uid: params[:tenant_uid])
      end

      def authenticate_tenant_user
        return if current_user.present?

        respond_to do |format|
          format.html do
            redirect_to tenant_auth.iam_sign_in_path(
              tenant_uid: current_tenant.uid,
              redirect_url: request.fullpath
            )
          end
          format.json { render json: { error: I18n.t("errors.unauthorized") }, status: :unauthorized }
          format.any { head :unauthorized }
        end
      end

      def authorize_current_tenant
        authorize current_tenant, policy_class: ApplicationPolicy
      end

      def current_user
        tenant_user_id = session[:tnt_user_id] || session[:tenant_user_id]
        return @current_user = nil if tenant_user_id.blank?

        if current_tenant.blank?
          return @current_user = TenantAuth::User.find_by(id: tenant_user_id)
        end

        if defined?(@current_user) && @current_user.present? &&
           @current_user.id == tenant_user_id && @current_user.tenant_id == current_tenant.id
          return @current_user
        end

        @current_user = TenantAuth::User.find_by(id: tenant_user_id, tenant_id: current_tenant.id)
      end

      def apply_user_preferences
        user = current_user
        return if user.blank?

        if params[:locale].blank? && user.respond_to?(:locale) && user.locale.present?
          I18n.locale = normalized_locale(user.locale)
        end

        return unless user.respond_to?(:time_zone)

        user_time_zone = user.time_zone.to_s.strip
        return if user_time_zone.blank?

        resolved_time_zone = ActiveSupport::TimeZone[user_time_zone]
        Time.zone = resolved_time_zone.name if resolved_time_zone.present?
      end
  end
end
