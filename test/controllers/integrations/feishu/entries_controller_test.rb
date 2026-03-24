require "test_helper"

class IntegrationsFeishuEntriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tenant = create(:tenant, :acme)
    @enterprise = create(:feishu_enterprise, :acme_enterprise, tenant: @tenant)
  end

  test "entry redirects to feishu oauth when tenant_uid provided" do
    Feishu::OauthState.expects(:generate).returns("signed-state")

    oauth_client = mock("feishu-oauth-client")
    Feishu::OauthClient.expects(:new).returns(oauth_client)
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
    Feishu::OauthClient.expects(:new).returns(oauth_client)
    oauth_client.expects(:authorization_url).with(state: "signed-state").returns("https://open.feishu.cn/auth")

    get "/integrations/feishu/entry", params: { tenant_key: @enterprise.tenant_key }

    assert_response :redirect
    assert_redirected_to "https://open.feishu.cn/auth"
  end

  test "entry redirects to dashboard when user already signed in" do
    user = create(:tenant_user, :alice, tenant: @tenant)
    sign_in_tenant_user(tenant_uid: @tenant.uid, name: user.name)

    Feishu::OauthClient.expects(:new).never

    get "/integrations/feishu/entry", params: { tenant_uid: @tenant.uid }

    assert_response :redirect
    assert_redirected_to "/t/acme/dashboard"
  end

  test "entry returns bad request when tenant parameters missing" do
    get "/integrations/feishu/entry", as: :json

    assert_response :bad_request
    assert_equal "param is missing or the value is empty or invalid: tenant_uid", json_body["error"]
  end
end
