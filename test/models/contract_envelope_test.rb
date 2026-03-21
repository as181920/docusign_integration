require "test_helper"

class ContractEnvelopeTest < ActiveSupport::TestCase
  test "factory is valid" do
    assert_predicate build(:contract_envelope), :valid?
  end

  test "requires unique envelope_id" do
    existing = create(:contract_envelope, envelope_id: "env_acme_001")

    beta_tenant = create(:tenant, :beta)
    beta_user = create(:tenant_user, tenant: beta_tenant, name: "bob")
    beta_contract = create(:contract, tenant: beta_tenant, creator_tenant_user: beta_user, contract_no: "C-BETA-001")
    beta_connection = create(:tenant_docusign_connection, :beta_connection, tenant: beta_tenant, connected_by_tenant_user: beta_user)

    duplicate = ContractEnvelope.new(
      contract: beta_contract,
      tenant_docusign_connection: beta_connection,
      envelope_id: existing.envelope_id
    )

    assert_not duplicate.valid?
    assert duplicate.errors.of_kind?(:envelope_id, :taken)
  end

  test "has expected enum status" do
    assert ContractEnvelope.statuses.key?("sent")
    assert ContractEnvelope.statuses.key?("completed")
  end
end
