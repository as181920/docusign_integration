module Tenant
  class DocusignTemplateSyncsController < BaseController
    def create
      result = Docusign::TemplateSyncService.call(tenant: current_tenant)

      audit(
        action: "docusign_templates_synced",
        data: result
      )

      respond_to do |format|
        format.html do
          redirect_to tenant_contract_templates_path(tenant_uid: current_tenant.uid),
            notice: t(
              "tenant.contract_templates.notices.synced",
              total_count: result[:total_count],
              created_count: result[:created_count],
              updated_count: result[:updated_count],
              skipped_count: result[:skipped_count]
            )
        end
        format.json { render json: result, status: :ok }
      end
    rescue Docusign::Error, ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound => e
      respond_to do |format|
        format.html do
          redirect_to tenant_contract_templates_path(tenant_uid: current_tenant.uid), alert: e.message
        end
        format.json { render json: { error: e.message }, status: :unprocessable_entity }
      end
    end
  end
end
