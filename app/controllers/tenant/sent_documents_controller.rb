module Tenant
  class SentDocumentsController < BaseController
    def index
      @q = policy_scope_records(sent_document_scope).ransack(params[:q])
      @sent_documents = @q.result.page(params[:page]).per(pagination_per(default: 10))

      respond_to do |format|
        format.html
        format.json { render json: @sent_documents.as_json(include: :contract_envelope) }
      end
    end

    private

      def sent_document_scope
        Contract
          .includes(:contract_envelope)
          .where(tenant: current_tenant, status: %w[sent delivered signed declined voided archived])
          .order(created_at: :desc)
      end
  end
end
