module Tenant
  class ContractTemplatesController < BaseController
    def index
      templates = ContractTemplate.where(tenant: current_tenant).order(name: :asc, version: :desc)
      render json: templates
    end

    def show
      template = ContractTemplate.find_by!(id: params[:id], tenant: current_tenant)
      render json: template
    end

    def create
      template = ContractTemplate.new(contract_template_params)
      template.tenant = current_tenant
      template.version = next_version_for(template.name) if params.dig(:contract_template, :version).blank?

      if template.save
        audit!(action: "contract_template_created", target: template)
        render json: template, status: :created
      else
        render json: { errors: template.errors.full_messages }, status: :unprocessable_entity
      end
    end

    def update
      template = ContractTemplate.find_by!(id: params[:id], tenant: current_tenant)
      if template.update(contract_template_params)
        audit!(action: "contract_template_updated", target: template)
        render json: template
      else
        render json: { errors: template.errors.full_messages }, status: :unprocessable_entity
      end
    end

    private

      def contract_template_params
        params.require(:contract_template).permit(:name, :version, :status, :docusign_template_id, :description, metadata: {})
      end

      def next_version_for(name)
        ContractTemplate.where(tenant: current_tenant, name: name).maximum(:version).to_i + 1
      end
  end
end
