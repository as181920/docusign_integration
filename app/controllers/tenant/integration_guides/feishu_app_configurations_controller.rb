module Tenant
  module IntegrationGuides
    class FeishuAppConfigurationsController < BaseController
      def edit
        assign_feishu_guide_data(editing: true)

        respond_to do |format|
          format.html { render "tenant/integration_guides/feishu" }
          format.turbo_stream { render_configuration_frame }
        end
      end

      def update
        enterprise = FeishuEnterprise.find_or_initialize_by(tenant: current_tenant)
        attrs = feishu_app_configuration_params.to_h
        attrs["app_secret"] = enterprise.app_secret if attrs["app_secret"].blank? && enterprise.app_secret.present?
        enterprise.assign_attributes(attrs)
        enterprise.status ||= "active"
        enterprise.save!

        audit(
          action: "feishu_app_configuration_updated",
          target: enterprise,
          data: {
            tenant_uid: current_tenant.uid,
            app_id: enterprise.app_id
          }
        )

        respond_to do |format|
          format.html do
            redirect_to tenant_integration_guides_feishu_path(tenant_uid: current_tenant.uid),
                        notice: t("tenant.integration_guides.feishu.configuration.updated")
          end
          format.turbo_stream do
            assign_feishu_guide_data(editing: false)
            @feishu_enterprise = enterprise
            flash.now[:notice] = t("tenant.integration_guides.feishu.configuration.updated")
            render_configuration_frame
          end
        end
      rescue ActiveRecord::RecordInvalid => e
        redirect_to edit_tenant_integration_guides_feishu_app_configuration_path(tenant_uid: current_tenant.uid),
                    alert: e.record.errors.full_messages.to_sentence
      end

      private

        def assign_feishu_guide_data(editing:)
          @editing_feishu_configuration = editing
          @feishu_enterprise = FeishuEnterprise.find_or_initialize_by(tenant: current_tenant)
          @feishu_entry_url = integrations_feishu_entry_url(tenant_uid: current_tenant.uid)
          @feishu_callback_url = integrations_feishu_callback_url
          @feishu_events_url = integrations_feishu_events_url
          @feishu_oauth_authorize_path = tenant_integration_guides_feishu_oauth_authorization_path(tenant_uid: current_tenant.uid)
          @feishu_app_configuration_path = tenant_integration_guides_feishu_app_configuration_path(tenant_uid: current_tenant.uid)
          @feishu_app_configuration_edit_path = edit_tenant_integration_guides_feishu_app_configuration_path(tenant_uid: current_tenant.uid)
          @feishu_connection_test_path = tenant_integration_guides_feishu_connection_test_path(tenant_uid: current_tenant.uid)
        end

        def render_configuration_frame
          partial_name = @editing_feishu_configuration ? "tenant/integration_guides/feishu_app_configuration_edit" : "tenant/integration_guides/feishu_app_configuration_show"

          render turbo_stream: turbo_stream.replace(
            "feishu_app_configuration",
            partial: partial_name,
            locals: {
              feishu_enterprise: @feishu_enterprise
            }
          )
        end

        def feishu_app_configuration_params
          params.require(:feishu_enterprise).permit(
            :app_id,
            :app_secret,
            :app_verification_token,
            :app_encrypt_key
          )
        end
    end
  end
end
