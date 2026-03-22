module Tenant
  module Contracts
    class DocusignEnvelopeSubmissionsController < BaseController
      def create
        contract = find_contract
        envelope = Docusign::EnvelopeSender.call(contract: contract)

        audit(
          action: "contract_sent_to_docusign",
          target: contract,
          data: {
            envelope_id: envelope.envelope_id,
            envelope_status: envelope.status
          }
        )

        respond_to do |format|
          format.html do
            redirect_to tenant_contract_path(tenant_uid: current_tenant.uid, id: contract.id),
              notice: t("tenant.contracts.notices.sent_to_docusign", envelope_id: envelope.envelope_id)
          end
          format.json do
            render json: {
              message: t("tenant.contracts.messages.sent_to_docusign"),
              contract: contract.reload.as_json(include: %i[contract_signers contract_envelope]),
              envelope: envelope
            }
          end
        end
      rescue Docusign::Error, ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound => e
        respond_to do |format|
          format.html do
            redirect_to tenant_contract_path(tenant_uid: current_tenant.uid, id: params[:contract_id]), alert: e.message
          end
          format.json { render json: { error: e.message }, status: :unprocessable_entity }
        end
      end

      private

        def find_contract
          Contract.find_by!(id: params[:contract_id], tenant: current_tenant)
        end
    end
  end
end
