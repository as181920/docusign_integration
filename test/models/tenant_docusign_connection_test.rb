require "test_helper"

class TenantDocusignConnectionTest < ActiveSupport::TestCase
  test "factory is valid" do
    assert_predicate build(:tenant_docusign_connection), :valid?
  end

  test "requires unique docusign_account_id" do
    create(:tenant_docusign_connection, docusign_account_id: "acct_acme")

    duplicate = TenantDocusignConnection.new(
      tenant: create(:tenant, :beta),
      docusign_account_id: "acct_acme"
    )

    assert_not duplicate.valid?
    assert duplicate.errors.of_kind?(:docusign_account_id, :taken)
  end

  test "requires one connection per tenant" do
    tenant = create(:tenant, :acme)
    create(:tenant_docusign_connection, tenant: tenant, docusign_account_id: "acct_acme")

    duplicate = TenantDocusignConnection.new(
      tenant: tenant,
      docusign_account_id: "another-account"
    )

    assert_not duplicate.valid?
    assert duplicate.errors.of_kind?(:tenant_id, :taken)
  end

  test "cannot destroy when envelopes exist" do
    envelope = create(:contract_envelope)
    connection = envelope.tenant_docusign_connection

    assert_not connection.destroy
    assert_predicate connection.errors[:base], :present?
  end
end
