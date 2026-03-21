module TenantScoped
  class ContractSignersController < BaseController
    def index
      contract = Contract.find_by!(id: params[:contract_id], tenant: current_tenant)
      render json: contract.contract_signers.order(:routing_order, :id)
    end

    def create
      contract = Contract.find_by!(id: params[:contract_id], tenant: current_tenant)
      signer = contract.contract_signers.new(contract_signer_params)

      if signer.save
        audit!(action: "contract_signer_created", target: contract, data: { signer_id: signer.id })
        render json: signer, status: :created
      else
        render json: { errors: signer.errors.full_messages }, status: :unprocessable_entity
      end
    end

    private

      def contract_signer_params
        params.require(:contract_signer).permit(:name, :email, :role_name, :routing_order, :signing_type, metadata: {})
      end
  end
end
