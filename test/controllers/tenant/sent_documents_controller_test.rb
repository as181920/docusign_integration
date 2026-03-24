require "test_helper"

class TenantSentDocumentsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tenant = create(:tenant, :acme)
    @tenant_user = create(:tenant_user, :alice, tenant: @tenant)
    sign_in_tenant_user(tenant_uid: @tenant.uid, name: @tenant_user.name)

    @sent_contract = create(:contract, tenant: @tenant, status: :sent)
    create(:contract_envelope, contract: @sent_contract, envelope_id: "env-sent-001")
    create(:contract, tenant: @tenant, status: :draft)
  end

  test "index only returns sent-like contracts" do
    get "/t/acme/sent_documents.json"

    assert_response :success
    assert_equal 1, json_body.size
    assert_equal @sent_contract.id, json_body.first["id"]
  end

  test "index html renders list page" do
    get "/t/acme/sent_documents"

    assert_response :success
    assert_select "h1", text: "已发送文档"
    assert_select "table", 1
  end
end
