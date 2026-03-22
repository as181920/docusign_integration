require "test_helper"

class TenantContractSignersControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tenant = create(:tenant, :acme)
    @tenant_user = create(:tenant_user, :alice, tenant: @tenant)
    @contract = create(:contract, :acme_contract, tenant: @tenant, creator_tenant_user: @tenant_user)
    create(:contract_signer, contract: @contract, name: "Alice Signer", email: "alice.signer@example.com", role_name: "signer", routing_order: 1)
    create(:contract_signer, :carbon_copy, contract: @contract, name: "Legal CC", email: "legal.cc@example.com", role_name: "cc", routing_order: 2)

    sign_in_tenant_user(tenant_uid: @tenant.uid, name: @tenant_user.name)
  end

  test "index returns contract signers" do
    get "/t/acme/contracts/#{@contract.id}/signers", as: :json

    assert_response :success
    assert_equal 2, json_body.size
  end

  test "index supports pagination and filtering" do
    create_list(:contract_signer, 8, contract: @contract, role_name: "approver")
    create(:contract_signer, contract: @contract, email: "finance.special@example.com", role_name: "finance")

    get "/t/acme/contracts/#{@contract.id}/signers", params: {
      per: 3,
      q: { email_cont: "finance.special" }
    }, as: :json

    assert_response :success
    assert_equal 1, json_body.size
    assert_equal "finance.special@example.com", json_body.first["email"]
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
      }, as: :json
    end

    assert_response :created
    assert_equal "new.signer@example.com", json_body["email"]
  end

  test "create signer validation error" do
    post "/t/acme/contracts/#{@contract.id}/signers", params: { contract_signer: { name: "Only Name" } }, as: :json

    assert_response :unprocessable_entity
    assert_predicate json_body["errors"], :any?
  end
end
