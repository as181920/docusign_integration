require "test_helper"

class IntegrationsFeishuCallbacksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tenant = create(:tenant, :acme)
    create(:feishu_enterprise, :acme_enterprise, tenant: @tenant)
  end

  test "callback binds tenant enterprise and identity" do
    platform_user = create(:platform_user, name: "platform_alice")
    tenant_user = create(:tenant_user, :alice, tenant: @tenant)
    identity = create(
      :external_identity,
      tenant: @tenant,
      user: platform_user,
      tenant_user: tenant_user,
      provider_uid: "union_acme_alice",
      union_id: "union_acme_alice",
      open_id: "open_acme_alice"
    )

    Feishu::UserProvisioningService.stubs(:call).returns(identity)
    assert_difference "AuditLog.count", +1 do
      get "/integrations/feishu/callback", params: {
        tenant_uid: @tenant.uid,
        tenant_key: "fs_acme_key",
        union_id: identity.union_id,
        open_id: identity.open_id,
        tenant_name: "ACME Tenant New Name"
      }
    end

    assert_response :success
    assert_equal @tenant.uid, json_body["tenant_uid"]
    assert_equal identity.user_id, json_body["user_id"]
  end

  test "callback rejects tenant key mismatch" do
    get "/integrations/feishu/callback", params: {
      tenant_uid: "acme",
      tenant_key: "wrong-key"
    }

    assert_response :unprocessable_entity
    assert_match "tenant_key does not match", json_body["error"]
  end

  test "callback returns not found for unknown tenant" do
    get "/integrations/feishu/callback", params: { tenant_uid: "missing" }

    assert_response :not_found
  end
end
