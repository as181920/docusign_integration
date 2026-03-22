module Integrations
  module Feishu
    class CallbacksController < ApplicationController
      rescue_from ActiveRecord::RecordNotFound, with: :render_not_found

      def show
        skip_authorization
        tenant = TenantAuth::Tenant.find_by!(uid: params[:tenant_uid])
        incoming_tenant_key = params[:tenant_key].presence || params[:tenantKey].presence

        enterprise = FeishuEnterprise.find_or_initialize_by(tenant: tenant)

        if enterprise.persisted? && enterprise.tenant_key.present? && incoming_tenant_key.present? && enterprise.tenant_key != incoming_tenant_key
          return render json: { error: t("integrations.feishu.callbacks.errors.tenant_key_mismatch") }, status: :unprocessable_entity
        end

        enterprise.tenant_key = incoming_tenant_key if incoming_tenant_key.present?
        enterprise.app_id = ENV.fetch("feishu_app_id", nil)
        enterprise.name = params[:tenant_name] if params[:tenant_name].present?
        enterprise.raw_payload = params.to_unsafe_h
        enterprise.save!

        identity = provision_identity_if_possible(tenant: tenant)
        bind_session(identity)

        audit(
          tenant: tenant,
          actor: identity&.tenant_user,
          action: "feishu_callback_received",
          target: enterprise,
          data: {
            tenant_key: enterprise.tenant_key,
            identity_id: identity&.id,
            user_id: identity&.user_id,
            tenant_user_id: identity&.tenant_user_id
          }
        )

        render json: {
          message: t("integrations.feishu.callbacks.messages.received"),
          tenant_uid: tenant.uid,
          tenant_key: enterprise.tenant_key,
          user_id: identity&.user_id,
          tenant_user_id: identity&.tenant_user_id
        }
      rescue ActiveRecord::RecordInvalid => e
        render json: { error: e.record.errors.full_messages.to_sentence }, status: :unprocessable_entity
      end

      private

        def provision_identity_if_possible(tenant:)
          auth_info = params.to_unsafe_h.slice("union_id", "open_id", "name", "avatar_url")
          return nil if auth_info["union_id"].blank? && auth_info["open_id"].blank?

          ::Feishu::UserProvisioningService.call(tenant: tenant, auth_info: auth_info)
        end

        def bind_session(identity)
          return if identity.blank?

          session[:tenant_user_id] = identity.tenant_user_id if identity.tenant_user_id.present?
          session[:user_id] = identity.user_id if identity.user_id.present?
        end

        def render_not_found(exception)
          render json: { error: exception.message }, status: :not_found
        end
    end
  end
end
