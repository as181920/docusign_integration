require "test_helper"

module Docusign
  class RecipientIdentityTest < ActiveSupport::TestCase
    test "builds deterministic client user id" do
      signer = create(:contract_signer)

      assert_equal "contract-#{signer.contract_id}-signer-#{signer.id}", RecipientIdentity.client_user_id(signer)
    end
  end
end
