require "test_helper"

module Docusign
  class EnvelopeSenderTest < ActiveSupport::TestCase
    def create_acme_context
      tenant = create(:tenant, :acme)
      tenant_user = create(:tenant_user, :alice, tenant: tenant)
      connection = create(:tenant_docusign_connection, :acme_connection, tenant: tenant, connected_by_tenant_user: tenant_user)
      [tenant, tenant_user, connection]
    end

    test "sends envelope and persists contract envelope for template contract" do
      tenant, tenant_user, connection = create_acme_context
      contract = create(:contract, :acme_contract, tenant: tenant, creator_tenant_user: tenant_user)
      create(:contract_signer, contract: contract, name: "Alice Signer", email: "alice.signer@example.com", role_name: "signer", routing_order: 1)
      result = { "envelopeId" => "env-new-001", "status" => "sent" }

      ApiClient.expects(:post!).returns(result)

      envelope = EnvelopeSender.call!(contract: contract)

      assert_equal "env-new-001", envelope.envelope_id
      assert_equal "sent", envelope.status
      assert_equal connection.id, envelope.tenant_docusign_connection_id

      contract.reload

      assert_equal "sent", contract.status
      assert_predicate contract.sent_at, :present?
    end

    test "raises when no signer exists" do
      tenant, tenant_user, = create_acme_context
      contract = create(:contract, :acme_contract_without_template, tenant: tenant, creator_tenant_user: tenant_user)

      assert_raises(Docusign::Error) { EnvelopeSender.call!(contract: contract) }
    end

    test "sends envelope with document payload when template missing" do
      tenant, tenant_user, connection = create_acme_context
      contract = create(:contract, :acme_contract_without_template, tenant: tenant, creator_tenant_user: tenant_user)
      contract.contract_signers.create!(
        name: "Manual Signer",
        email: "manual.signer@example.com",
        role_name: "signer",
        routing_order: 1,
        signing_type: :signer
      )

      file = Rails.root.join("test/fixtures/files/contract.pdf")
      contract.documents.attach(io: File.open(file), filename: "contract.pdf", content_type: "application/pdf")

      captured_body = nil
      expected_connection_id = connection.id
      ApiClient.expects(:post!).with do |*args, **kwargs|
        params = kwargs.presence || args.first || {}

        assert_equal expected_connection_id, params[:connection].id
        assert_equal "/envelopes", params[:path]
        captured_body = params[:body]
        true
      end.returns({ "envelopeId" => "env-doc-001", "status" => "sent" })

      EnvelopeSender.call!(contract: contract)

      assert_predicate captured_body[:documents], :present?
      assert_equal "sent", captured_body[:status]
    end
  end
end
