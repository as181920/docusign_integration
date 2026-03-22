module Tenant
  class ContractTemplatesController < BaseController
    before_action :set_template, only: %i[show edit update]

    def index
      @q = policy_scope_records(template_scope).ransack(params[:q])
      @templates = @q.result.page(params[:page]).per(pagination_per(default: 10))

      respond_to do |format|
        format.html
        format.json { render json: @templates }
      end
    end

    def new
      @template = ContractTemplate.new(status: :active)
    end

    def show
      respond_to do |format|
        format.html
        format.json { render json: @template }
      end
    end

    def edit; end

    def create
      @template = ContractTemplate.new(contract_template_params)
      @template.tenant = current_tenant
      @template.version = next_version_for(@template.name) if params.dig(:contract_template, :version).blank?

      if @template.save
        audit(action: "contract_template_created", target: @template)
        respond_to do |format|
          format.html do
            redirect_to tenant_contract_template_path(tenant_uid: current_tenant.uid, id: @template.id),
              notice: t("tenant.contract_templates.notices.created")
          end
          format.json { render json: @template, status: :created }
        end
      else
        respond_to do |format|
          format.html do
            flash.now[:alert] = @template.errors.full_messages.to_sentence
            render :new, status: :unprocessable_entity
          end
          format.json { render json: { errors: @template.errors.full_messages }, status: :unprocessable_entity }
        end
      end
    end

    def update
      if @template.update(contract_template_params)
        audit(action: "contract_template_updated", target: @template)
        respond_to do |format|
          format.html do
            redirect_to tenant_contract_template_path(tenant_uid: current_tenant.uid, id: @template.id),
              notice: t("tenant.contract_templates.notices.updated")
          end
          format.json { render json: @template }
        end
      else
        respond_to do |format|
          format.html do
            flash.now[:alert] = @template.errors.full_messages.to_sentence
            render :edit, status: :unprocessable_entity
          end
          format.json { render json: { errors: @template.errors.full_messages }, status: :unprocessable_entity }
        end
      end
    end

    private

      def set_template
        @template = template_scope.find(params[:id])
      end

      def template_scope
        ContractTemplate.where(tenant: current_tenant).order(name: :asc, version: :desc)
      end

      def contract_template_params
        params.require(:contract_template).permit(:name, :version, :status, :docusign_template_id, :description, metadata: {})
      end

      def next_version_for(name)
        ContractTemplate.where(tenant: current_tenant, name: name).maximum(:version).to_i + 1
      end
  end
end
