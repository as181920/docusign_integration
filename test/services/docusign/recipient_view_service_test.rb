require "test_helper"

module Docusign
  class RecipientViewServiceTest < ActiveSupport::TestCase
    test "returns recipient signing url" do
      tenant = create(:tenant, :acme)
      tenant_user = create(:tenant_user, :alice, tenant: tenant)
      connection = create(:tenant_docusign_connection, :acme_connection, tenant: tenant, connected_by_tenant_user: tenant_user)
      contract = create(:contract, :acme_contract, tenant: tenant, creator_tenant_user: tenant_user)
      signer = create(:contract_signer, contract: contract, name: "Alice Signer", email: "alice.signer@example.com", role_name: "signer", routing_order: 1)
      create(:contract_envelope, :acme_envelope, contract: contract, tenant_docusign_connection: connection)

      expected_connection_id = connection.id
      ApiClient.expects(:post).with do |*args, **kwargs|
        params = kwargs.presence || args.first || {}

        assert_equal expected_connection_id, params[:connection].id
        assert_equal "/envelopes/env_acme_001/views/recipient", params[:path]
        assert_equal signer.email, params[:body][:email]
        true
      end.returns({ "url" => "https://docusign.example.com/embedded" })

      url = RecipientViewService.call(
        contract: contract,
        signer_email: signer.email,
        return_url: "https://app.example.com/return"
      )

      assert_equal "https://docusign.example.com/embedded", url
    end

    test "raises when contract envelope missing" do
      contract = create(:contract, :acme_contract_without_template)
      contract.contract_signers.create!(
        name: "A",
        email: "a@example.com",
        role_name: "signer",
        signing_type: :signer
      )

      assert_raises(Docusign::Error) do
        RecipientViewService.call(contract: contract, signer_email: "a@example.com", return_url: "https://app.example.com")
      end
    end
  end
end
