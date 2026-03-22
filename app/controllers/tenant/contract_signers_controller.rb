module Tenant
  class ContractSignersController < BaseController
    def index
      contract = find_contract
      @q = policy_scope_records(contract.contract_signers).ransack(params[:q])
      signers = @q.result.order(:routing_order, :id).page(params[:page]).per(pagination_per(default: 20))

      respond_to do |format|
        format.json { render json: signers }
      end
    end

    def create
      contract = find_contract
      signer = contract.contract_signers.new(contract_signer_params)

      if signer.save
        audit(action: "contract_signer_created", target: contract, data: { signer_id: signer.id })
        respond_to do |format|
          format.html do
            redirect_to tenant_contract_path(tenant_uid: current_tenant.uid, id: contract.id), notice: t("tenant.contracts.signers.notices.created")
          end
          format.json { render json: signer, status: :created }
        end
      else
        respond_to do |format|
          format.html do
            redirect_to tenant_contract_path(tenant_uid: current_tenant.uid, id: contract.id),
              alert: signer.errors.full_messages.to_sentence
          end
          format.json { render json: { errors: signer.errors.full_messages }, status: :unprocessable_entity }
        end
      end
    end

    private

      def find_contract
        Contract.find_by!(id: params[:contract_id], tenant: current_tenant)
      end

      def contract_signer_params
        params.require(:contract_signer).permit(:name, :email, :role_name, :routing_order, :signing_type, metadata: {})
      end
  end
end
