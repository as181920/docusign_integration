require "test_helper"

class TenantScopedContractSignersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tenant = create(:tenant, :acme)
    @tenant_user = create(:tenant_user, :alice, tenant: @tenant)
    @contract = create(:contract, :acme_contract, tenant: @tenant, creator_tenant_user: @tenant_user)
    create(:contract_signer, contract: @contract, name: "Alice Signer", email: "alice.signer@example.com", role_name: "signer", routing_order: 1)
    create(:contract_signer, :carbon_copy, contract: @contract, name: "Legal CC", email: "legal.cc@example.com", role_name: "cc", routing_order: 2)
  end

  test "index returns contract signers" do
    get "/t/acme/contracts/#{@contract.id}/signers"

    assert_response :success
    assert_equal 2, json_body.size
  end

  test "create signer success" do
    assert_difference ["ContractSigner.count", "AuditLog.count"], +1 do
      post "/t/acme/contracts/#{@contract.id}/signers", params: {
        contract_signer: {
          name: "New Signer",
          email: "new.signer@example.com",
          role_name: "finance_signer",
          routing_order: 3,
          signing_type: "signer"
        }
      }
    end

    assert_response :created
    assert_equal "new.signer@example.com", json_body["email"]
  end

  test "create signer validation error" do
    post "/t/acme/contracts/#{@contract.id}/signers", params: { contract_signer: { name: "Only Name" } }

    assert_response :unprocessable_entity
    assert_predicate json_body["errors"], :any?
  end
end
