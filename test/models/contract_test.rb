require "test_helper"

class ContractTest < ActiveSupport::TestCase
  test "factory is valid" do
    assert_predicate build(:contract), :valid?
  end

  test "requires title and contract_no" do
    tenant = create(:tenant, :acme)
    contract = Contract.new(tenant: tenant, title: nil, contract_no: nil)

    assert_not contract.valid?
    assert contract.errors.of_kind?(:title, :blank)
    assert contract.errors.of_kind?(:contract_no, :blank)
  end

  test "enforces unique contract_no within tenant" do
    tenant = create(:tenant, :acme)
    existing = create(:contract, tenant: tenant, contract_no: "C-ACME-001")

    duplicate = Contract.new(
      tenant: tenant,
      title: "Duplicate",
      contract_no: existing.contract_no
    )

    assert_not duplicate.valid?
    assert duplicate.errors.of_kind?(:contract_no, :taken)
  end

  test "allows same contract_no across tenants" do
    tenant1 = create(:tenant, :acme)
    tenant2 = create(:tenant, :beta)
    create(:contract, tenant: tenant1, contract_no: "C-ACME-001")

    contract = Contract.new(
      tenant: tenant2,
      title: "Cross Tenant",
      contract_no: "C-ACME-001"
    )

    assert_predicate contract, :valid?
  end
end
