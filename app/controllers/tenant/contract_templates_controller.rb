module Tenant
  class ContractTemplatesController < BaseController
    before_action :set_template, only: %i[show edit update]

    def index
      @q = policy_scope_records(template_scope).ransack(params[:q])
      @q.sorts = "id desc" if @q.sorts.empty?
      @templates = @q.result.includes(:template_roles).page(params[:page]).per(pagination_per(default: 10))

      respond_to do |format|
        format.html
        format.json { render json: @templates }
      end
    end

    def new
      @template = ContractTemplate.new(status: :active, publish_state: :draft)
      build_role_slots(@template)
    end

    def show
      respond_to do |format|
        format.html
        format.json { render json: @template }
      end
    end

    def edit
      build_role_slots(@template)
    end

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
        build_role_slots(@template)

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
      attributes = params[:contract_template].present? ? contract_template_params : {}

      if @template.update(attributes)
        publish_result = publish_template_if_requested(@template)

        audit(action: "contract_template_updated", target: @template)

        respond_to do |format|
          format.html do
            redirect_to tenant_contract_template_path(tenant_uid: current_tenant.uid, id: @template.id),
              notice: update_notice_message(publish_result)
          end
          format.json do
            payload = @template.as_json
            payload["publish_result"] = publish_result if publish_result.present?
            render json: payload
          end
        end
      else
        build_role_slots(@template)

        respond_to do |format|
          format.html do
            flash.now[:alert] = @template.errors.full_messages.to_sentence
            render :edit, status: :unprocessable_entity
          end
          format.json { render json: { errors: @template.errors.full_messages }, status: :unprocessable_entity }
        end
      end
    rescue Docusign::Error, ActiveRecord::RecordNotFound => e
      respond_to do |format|
        format.html do
          flash.now[:alert] = e.message
          render :show, status: :unprocessable_entity
        end
        format.json { render json: { error: e.message }, status: :unprocessable_entity }
      end
    end

    private

      def set_template
        @template = template_scope.includes(:template_roles).find(params[:id])
      end

      def template_scope
        ContractTemplate.where(tenant: current_tenant)
      end

      def contract_template_params
        params.require(:contract_template).permit(
          :name,
          :version,
          :status,
          :description,
          :email_subject,
          :email_message,
          :docusign_template_id,
          { documents: [] },
          {
            template_roles_attributes: [
              :id,
              :role_name,
              :signer_name,
              :signer_email,
              :routing_order,
              :signing_type,
              :_destroy
            ]
          },
          metadata: {}
        )
      end

      def publish_template_if_requested(template)
        return nil unless ActiveModel::Type::Boolean.new.cast(params[:publish_to_docusign])

        Docusign::TemplatePublisher.call(template: template)
      end

      def update_notice_message(publish_result)
        return t("tenant.contract_templates.notices.updated") if publish_result.blank?

        t("tenant.contract_templates.notices.published", template_id: publish_result["templateId"] || publish_result["template_id"])
      end

      def build_role_slots(template, minimum: 3)
        current_size = template.template_roles.reject(&:marked_for_destruction?).size
        [minimum - current_size, 0].max.times do
          template.template_roles.build(routing_order: template.template_roles.size + 1, signing_type: :signer)
        end
      end

      def next_version_for(name)
        ContractTemplate.where(tenant: current_tenant, name: name).maximum(:version).to_i + 1
      end
  end
end
