require "test_helper"

class IntegrationsFeishuCallbacksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tenant = create(:tenant, :acme)
    create(:feishu_enterprise, :acme_enterprise, tenant: @tenant)
    @oauth_client = stub("feishu-oauth-client", app_id: "cli_test")
    Feishu::OauthClient.stubs(:for_enterprise!).returns(@oauth_client)
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
      }, as: :json
    end

    assert_response :success
    assert_equal @tenant.uid, json_body["tenant_uid"]
    assert_equal identity.user_id, json_body["user_id"]
  end

  test "callback rejects tenant key mismatch" do
    get "/integrations/feishu/callback", params: {
      tenant_uid: "acme",
      tenant_key: "wrong-key"
    }, as: :json

    assert_response :unprocessable_entity
    assert_equal I18n.t("integrations.feishu.callbacks.errors.tenant_key_mismatch"), json_body["error"]
  end

  test "callback returns not found for unknown tenant" do
    get "/integrations/feishu/callback", params: { tenant_uid: "missing" }, as: :json

    assert_response :not_found
  end

  test "callback resolves tenant by signed state and renders html" do
    state = Feishu::OauthState.generate(tenant_uid: @tenant.uid, return_to: "/t/acme/dashboard")

    get "/integrations/feishu/callback", params: { state: state, tenant_key: "fs_acme_key" }

    assert_response :success
    assert_includes response.body, I18n.t("integrations.feishu.callbacks.result.success_title")
    assert_includes response.body, "/t/acme/dashboard"
  end

  test "callback returns bad request when tenant context is missing" do
    get "/integrations/feishu/callback", params: { code: "oauth-code" }, as: :json

    assert_response :bad_request
  end

  test "callback rejects tenant key already bound to another tenant" do
    another_tenant = create(:tenant, uid: "beta", name: "Beta")
    create(:feishu_enterprise, tenant: another_tenant, tenant_key: "fs_beta_key")
    state = Feishu::OauthState.generate(tenant_uid: @tenant.uid, return_to: "/t/acme/dashboard")

    get "/integrations/feishu/callback", params: {
      state: state,
      tenant_key: "fs_beta_key"
    }, as: :json

    assert_response :unprocessable_entity
    assert_equal I18n.t("integrations.feishu.callbacks.errors.tenant_key_mismatch"), json_body["error"]
  end

  test "callback returns unauthorized when state invalid" do
    get "/integrations/feishu/callback", params: { state: "invalid" }, as: :json

    assert_response :unauthorized
    assert_match "invalid feishu oauth state", json_body["error"]
  end
end
