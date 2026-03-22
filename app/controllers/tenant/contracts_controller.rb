module Tenant
  class ContractsController < BaseController
    before_action :set_contract, only: :show

    def index
      @q = policy_scope_records(contract_scope).ransack(params[:q])
      @contracts = @q.result.page(params[:page]).per(pagination_per(default: 10))

      respond_to do |format|
        format.html
        format.json { render json: @contracts.as_json(include: :contract_envelope) }
      end
    end

    def new
      @contract = Contract.new(status: :draft)
      @contract_templates = template_scope
    end

    def show
      @signers = @contract.contract_signers.order(:routing_order, :id)
      @new_signer = @contract.contract_signers.new(signing_type: :signer)
      @embedded_signing_url = flash[:embedded_signing_url]
      @embedded_signing_email = flash[:embedded_signing_email]

      respond_to do |format|
        format.html
        format.json { render json: serialize_contract(@contract) }
      end
    end

    def create
      @contract = Contract.new(contract_params)
      @contract.tenant = current_tenant
      @contract.creator_tenant_user = current_user

      apply_template(@contract)

      if @contract.save
        audit(action: "contract_created", target: @contract, data: { contract_no: @contract.contract_no })
        respond_to do |format|
          format.html do
            redirect_to tenant_contract_path(tenant_uid: current_tenant.uid, id: @contract.id), notice: t("tenant.contracts.notices.created")
          end
          format.json { render json: serialize_contract(@contract), status: :created }
        end
      else
        respond_to do |format|
          format.html do
            @contract_templates = template_scope
            flash.now[:alert] = @contract.errors.full_messages.to_sentence
            render :new, status: :unprocessable_entity
          end
          format.json { render json: { errors: @contract.errors.full_messages }, status: :unprocessable_entity }
        end
      end
    rescue ActiveRecord::RecordNotFound => e
      respond_to do |format|
        format.html do
          @contract_templates = template_scope
          flash.now[:alert] = e.message
          render :new, status: :not_found
        end
        format.json { render json: { error: e.message }, status: :not_found }
      end
    end

    private

      def contract_scope
        Contract.includes(:contract_envelope).where(tenant: current_tenant).order(created_at: :desc)
      end

      def template_scope
        ContractTemplate.where(tenant: current_tenant, status: :active).order(name: :asc, version: :desc)
      end

      def set_contract
        @contract = Contract.includes(:contract_envelope, :contract_signers).find_by!(id: params[:id], tenant: current_tenant)
      end

      def contract_params
        params.require(:contract).permit(:title, :contract_no, :source, :language, :currency, :docusign_template_id, metadata: {})
      end

      def apply_template(contract)
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
