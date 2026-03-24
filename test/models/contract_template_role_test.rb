require "test_helper"

class ContractTemplateRoleTest < ActiveSupport::TestCase
  test "factory is valid" do
    assert_predicate build(:contract_template_role), :valid?
  end

  test "requires role_name" do
    role = build(:contract_template_role, role_name: nil)

    assert_not role.valid?
    assert role.errors.of_kind?(:role_name, :blank)
  end
end
