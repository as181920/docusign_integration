module Tenant
  class ContractsController < BaseController
    before_action :set_contract, only: :show

    def index
      contracts = Contract.where(tenant: current_tenant).order(created_at: :desc)
      render json: contracts.as_json(include: :contract_envelope)
    end

    def show
      render json: serialize_contract(@contract)
    end

    def create
      contract = Contract.new(contract_params)
      contract.tenant = current_tenant
      contract.creator_tenant_user = current_tenant_user

      apply_template!(contract)

      if contract.save
        audit!(action: "contract_created", target: contract, data: { contract_no: contract.contract_no })
        render json: serialize_contract(contract), status: :created
      else
        render json: { errors: contract.errors.full_messages }, status: :unprocessable_entity
      end
    rescue ActiveRecord::RecordNotFound => e
      render json: { error: e.message }, status: :not_found
    end

    private

      def set_contract
        @contract = Contract.find_by!(id: params[:id], tenant: current_tenant)
      end

      def contract_params
        params.require(:contract).permit(:title, :contract_no, :source, :language, :currency, :docusign_template_id, metadata: {})
      end

      def apply_template!(contract)
        template_id = params.dig(:contract, :contract_template_id)
        return if template_id.blank?

        template = ContractTemplate.find_by!(id: template_id, tenant: current_tenant)
        contract.docusign_template_id = template.docusign_template_id if contract.docusign_template_id.blank?
        contract.metadata = contract.metadata.to_h.merge(
          "contract_template_id" => template.id,
          "contract_template_name" => template.name,
          "contract_template_version" => template.version
        )
      end

      def serialize_contract(contract)
        contract.as_json(include: %i[contract_signers contract_envelope])
      end
  end
end
