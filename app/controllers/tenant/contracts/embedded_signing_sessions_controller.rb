module Tenant
  module Contracts
    class EmbeddedSigningSessionsController < BaseController
      def create
        contract = find_contract
        signer_email = params.require(:signer_email)
        return_url = resolve_return_url(contract)

        signing_url = Docusign::RecipientViewService.call!(
          contract: contract,
          signer_email: signer_email,
          return_url: return_url
        )

        audit!(
          action: "contract_embedded_signing_url_generated",
          target: contract,
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
