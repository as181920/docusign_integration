require "test_helper"

class IntegrationsFeishuEntriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tenant = create(:tenant, :acme)
    @enterprise = create(:feishu_enterprise, :acme_enterprise, tenant: @tenant)
  end

  test "entry redirects to feishu oauth when tenant_uid provided" do
    Feishu::OauthState.expects(:generate).returns("signed-state")

    oauth_client = mock("feishu-oauth-client")
    Feishu::OauthClient.expects(:for_enterprise!).returns(oauth_client)
    oauth_client.expects(:authorization_url).with(state: "signed-state").returns("https://open.feishu.cn/auth")

    assert_difference "AuditLog.count", +1 do
      get "/integrations/feishu/entry", params: { tenant_uid: "acme" }
    end

    assert_response :redirect
    assert_redirected_to "https://open.feishu.cn/auth"
  end

  test "entry resolves tenant by tenant_key" do
    Feishu::OauthState.expects(:generate).returns("signed-state")

    oauth_client = mock("feishu-oauth-client")
    Feishu::OauthClient.expects(:for_enterprise!).returns(oauth_client)
    oauth_client.expects(:authorization_url).with(state: "signed-state").returns("https://open.feishu.cn/auth")

    get "/integrations/feishu/entry", params: { tenant_key: @enterprise.tenant_key }

    assert_response :redirect
    assert_redirected_to "https://open.feishu.cn/auth"
  end

  test "entry redirects to dashboard when user already signed in" do
    user = create(:tenant_user, :alice, tenant: @tenant)
    sign_in_tenant_user(tenant_uid: @tenant.uid, name: user.name)

    Feishu::OauthClient.expects(:for_enterprise!).never
    Feishu::OauthClient.expects(:new).never

    get "/integrations/feishu/entry", params: { tenant_uid: @tenant.uid }

    assert_response :redirect
    assert_redirected_to "/t/acme/dashboard"
  end

  test "entry renders tenant resolution guide when tenant parameters missing" do
    Feishu::OauthClient.expects(:for_enterprise!).never

    get "/integrations/feishu/entry"

    assert_response :bad_request
    assert_includes response.body, I18n.t("integrations.feishu.entries.resolve_tenant.bad_request_title")
  end

  test "entry renders tenant resolution guide when tenant_key is not bound" do
    get "/integrations/feishu/entry", params: { tenant_key: "tk_not_bound" }

    assert_response :not_found
    assert_includes response.body, I18n.t("integrations.feishu.entries.resolve_tenant.not_found_title")
    assert_match %r{name="tenant_key"}, response.body
    assert_match %r{value="tk_not_bound"}, response.body
  end
end
