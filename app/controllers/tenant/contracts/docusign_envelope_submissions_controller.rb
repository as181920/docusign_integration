module Tenant
  module Contracts
    class DocusignEnvelopeSubmissionsController < BaseController
      def create
        contract = find_contract
        envelope = Docusign::EnvelopeSender.call!(contract: contract)

        audit!(
          action: "contract_sent_to_docusign",
          target: contract,
          data: {
            envelope_id: envelope.envelope_id,
            envelope_status: envelope.status
          }
        )

        render json: {
          message: "contract sent to docusign",
          contract: contract.reload.as_json(include: %i[contract_signers contract_envelope]),
          envelope: envelope
        }
      rescue Docusign::Error, ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound => e
        render json: { error: e.message }, status: :unprocessable_entity
      end

      private

        def find_contract
          Contract.find_by!(id: params[:contract_id], tenant: current_tenant)
        end
    end
  end
end
