module TenantScoped
  class ContractsController < BaseController
    before_action :set_contract, only: %i[show send_to_docusign embedded_signing_url]

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

    def send_to_docusign
      envelope = Docusign::EnvelopeSender.call!(contract: @contract)

      audit!(
        action: "contract_sent_to_docusign",
        target: @contract,
        data: {
          envelope_id: envelope.envelope_id,
          envelope_status: envelope.status
        }
      )

      render json: {
        message: "contract sent to docusign",
        contract: serialize_contract(@contract.reload),
        envelope: envelope
      }
    rescue Docusign::Error, ActiveRecord::RecordInvalid, ActiveRecord::RecordNotFound => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def embedded_signing_url
      signer_email = params.require(:signer_email)
      return_url = resolve_return_url

      signing_url = Docusign::RecipientViewService.call!(
        contract: @contract,
        signer_email: signer_email,
        return_url: return_url
      )

      audit!(
        action: "contract_embedded_signing_url_generated",
        target: @contract,
        data: { signer_email: signer_email, return_url: return_url }
      )

      render json: {
        signer_email: signer_email,
        return_url: return_url,
        signing_url: signing_url
      }
    rescue ActionController::ParameterMissing => e
      render json: { error: e.message }, status: :bad_request
    rescue Docusign::Error, ActiveRecord::RecordNotFound => e
      render json: { error: e.message }, status: :unprocessable_entity
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

      def resolve_return_url
        explicit_return_url = params[:return_url].to_s.strip
        return default_return_url if explicit_return_url.blank?

        if explicit_return_url.start_with?("/")
          return "#{request.base_url}#{explicit_return_url}"
        end

        uri = URI.parse(explicit_return_url)
        return explicit_return_url if %w[http https].include?(uri.scheme)

        default_return_url
      rescue URI::InvalidURIError
        default_return_url
      end

      def default_return_url
        base_url = ENV.fetch("app_frontend_base_url", nil).presence || request.base_url
        "#{base_url}/t/#{current_tenant.uid}/contracts/#{@contract.id}"
      end
  end
end
