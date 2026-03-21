require "test_helper"

class ContractTemplateTest < ActiveSupport::TestCase
  test "factory is valid" do
    assert_predicate build(:contract_template), :valid?
  end

  test "requires positive version" do
    tenant = create(:tenant, :acme)
    template = ContractTemplate.new(tenant: tenant, name: "MSA", version: 0)

    assert_not template.valid?
    assert template.errors.of_kind?(:version, :greater_than)
  end

  test "enforces unique name and version within tenant" do
    tenant = create(:tenant, :acme)
    existing = create(:contract_template, tenant: tenant, name: "Master Service Agreement", version: 1)

    duplicate = ContractTemplate.new(
      tenant: tenant,
      name: existing.name,
      version: existing.version
    )

    assert_not duplicate.valid?
    assert duplicate.errors.of_kind?(:name, :taken)
  end
end
