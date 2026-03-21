module Docusign
  class RecipientViewService
    class << self
      def call!(contract:, signer_email:, return_url:)
        envelope = contract.contract_envelope
        raise Docusign::Error, "contract envelope not found" if envelope.blank?

        signer = contract.contract_signers.signer.find_by!(email: signer_email)
        connection = envelope.tenant_docusign_connection

        payload = {
          returnUrl: return_url,
          authenticationMethod: "none",
          email: signer.email,
          userName: signer.name,
          clientUserId: Docusign::RecipientIdentity.client_user_id(signer)
        }

        result = Docusign::ApiClient.post!(
          connection: connection,
          path: "/envelopes/#{envelope.envelope_id}/views/recipient",
          body: payload
        )

        result.fetch("url")
      end
    end
  end
end
