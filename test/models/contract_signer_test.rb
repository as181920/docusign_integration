require "test_helper"

class ContractSignerTest < ActiveSupport::TestCase
  test "factory is valid" do
    assert_predicate build(:contract_signer), :valid?
  end

  test "requires name email and role_name" do
    contract = create(:contract)
    signer = ContractSigner.new(contract: contract)

    assert_not signer.valid?
    assert signer.errors.of_kind?(:name, :blank)
    assert signer.errors.of_kind?(:email, :blank)
    assert signer.errors.of_kind?(:role_name, :blank)
  end

  test "enforces email uniqueness scoped by contract and role_name" do
    contract = create(:contract)
    existing = create(:contract_signer, contract: contract, email: "alice.signer@example.com", role_name: "signer")

    duplicate = ContractSigner.new(
      contract: contract,
      name: "Dup",
      email: existing.email,
      role_name: existing.role_name
    )

    assert_not duplicate.valid?
    assert duplicate.errors.of_kind?(:email, :taken)
  end

  test "allows same email under different role" do
    contract = create(:contract)
    existing = create(:contract_signer, contract: contract, email: "alice.signer@example.com", role_name: "signer")

    signer = ContractSigner.new(
      contract: contract,
      name: "Legal",
      email: existing.email,
      role_name: "legal_cc"
    )

    assert_predicate signer, :valid?
  end
end
