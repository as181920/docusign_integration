module Docusign
  class RecipientIdentity
    class << self
      def client_user_id(signer)
        "contract-#{signer.contract_id}-signer-#{signer.id}"
      end
    end
  end
end
