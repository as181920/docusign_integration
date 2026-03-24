require "stringio"

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
      load_embedded_signing_result

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
        params.require(:contract).permit(
          :title,
          :contract_no,
          :source,
          :language,
          :currency,
          :docusign_template_id,
          { documents: [] },
          metadata: {}
        )
      end

      def apply_template(contract)
        template_id = params.dig(:contract, :contract_template_id)
        return if template_id.blank?

        template = ContractTemplate.find_by!(id: template_id, tenant: current_tenant)
        contract.docusign_template_id = template.docusign_template_id if contract.docusign_template_id.blank?
        copy_template_documents_to_contract(contract: contract, template: template)
        build_signers_from_template_roles(contract: contract, template: template)
        contract.metadata = contract.metadata.to_h.merge(
          "contract_template_id" => template.id,
          "contract_template_name" => template.name,
          "contract_template_version" => template.version,
          "contract_template_publish_state" => template.publish_state
        )
      end

      def serialize_contract(contract)
        contract.as_json(include: %i[contract_signers contract_envelope])
      end

      def copy_template_documents_to_contract(contract:, template:)
        return if contract.documents.attached?
        return unless template.documents.attached?
        return if template.docusign_template_id.present?

        template.documents.each do |attachment|
          contract.documents.attach(
            io: StringIO.new(attachment.download),
            filename: attachment.filename.to_s,
            content_type: attachment.content_type
          )
        end
      end

      def build_signers_from_template_roles(contract:, template:)
        return if contract.contract_signers.any?

        template.template_roles.order(:routing_order, :id).each do |role|
          next if role.role_name.blank?
          next if role.signer_name.blank? || role.signer_email.blank?

          contract.contract_signers.build(
            name: role.signer_name,
            email: role.signer_email,
            role_name: role.role_name,
            routing_order: role.routing_order,
            signing_type: role.signing_type
          )
        end
      end

      def load_embedded_signing_result
        ref = params[:embedded_signing_ref]
        payload = Docusign::EmbeddedSigningResultStore.read_once(contract: @contract, ref: ref)

        @embedded_signing_url = payload&.fetch(:signing_url, nil)
        @embedded_signing_email = payload&.fetch(:signer_email, nil)
      end
  end
end
