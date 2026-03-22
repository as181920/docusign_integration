module Tenant
  module Contracts
    class EmbeddedSigningSessionsController < BaseController
      def create
        contract = find_contract
        signer_email = params.require(:signer_email)
        return_url = resolve_return_url(contract)

        signing_url = Docusign::RecipientViewService.call(
          contract: contract,
          signer_email: signer_email,
          return_url: return_url
        )

        audit(
          action: "contract_embedded_signing_url_generated",
          target: contract,
          data: { signer_email: signer_email, return_url: return_url }
        )

        respond_to do |format|
          format.html do
            flash[:embedded_signing_url] = signing_url
            flash[:embedded_signing_email] = signer_email
            redirect_to tenant_contract_path(tenant_uid: current_tenant.uid, id: contract.id),
              notice: t("tenant.contracts.notices.embedded_signing_link_generated")
          end
          format.json do
            render json: {
              signer_email: signer_email,
              return_url: return_url,
              signing_url: signing_url
            }
          end
        end
      rescue ActionController::ParameterMissing => e
        respond_to do |format|
          format.html do
            redirect_to tenant_contract_path(tenant_uid: current_tenant.uid, id: params[:contract_id]), alert: e.message
          end
          format.json { render json: { error: e.message }, status: :bad_request }
        end
      rescue Docusign::Error, ActiveRecord::RecordNotFound => e
        respond_to do |format|
          format.html do
            redirect_to tenant_contract_path(tenant_uid: current_tenant.uid, id: params[:contract_id]), alert: e.message
          end
          format.json { render json: { error: e.message }, status: :unprocessable_entity }
        end
      end

      private

        def find_contract
          Contract.find_by!(id: params[:contract_id], tenant: current_tenant)
        end

        def resolve_return_url(contract)
          explicit_return_url = params[:return_url].to_s.strip
          return default_return_url(contract) if explicit_return_url.blank?

          if explicit_return_url.start_with?("/")
            return "#{request.base_url}#{explicit_return_url}"
          end

          uri = URI.parse(explicit_return_url)
          return explicit_return_url if %w[http https].include?(uri.scheme)

          default_return_url(contract)
        rescue URI::InvalidURIError
          default_return_url(contract)
        end

        def default_return_url(contract)
          base_url = ENV.fetch("app_frontend_base_url", nil).presence || request.base_url
          "#{base_url}/t/#{current_tenant.uid}/contracts/#{contract.id}"
        end
    end
  end
end
