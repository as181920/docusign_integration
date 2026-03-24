require "test_helper"

class TenantFeishuOauthAuthorizationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tenant = create(:tenant, :acme)
    @user = create(:tenant_user, :alice, tenant: @tenant)
    sign_in_tenant_user(tenant_uid: @tenant.uid, name: @user.name)
  end

  test "create redirects to feishu oauth authorization url" do
    state = "signed-state"
    Feishu::OauthState.expects(:generate).returns(state)

    oauth_client = mock("feishu-oauth-client")
    Feishu::OauthClient.expects(:new).returns(oauth_client)
    oauth_client.expects(:authorization_url).with(state: state).returns("https://open.feishu.cn/auth")

    assert_difference "AuditLog.count", +1 do
      post "/t/acme/integration_guides/feishu_oauth_authorization"
    end

    assert_response :redirect
    assert_redirected_to "https://open.feishu.cn/auth"
  end

  test "create redirects back to guide when oauth config invalid" do
    Feishu::OauthClient.expects(:new).raises(Feishu::ConfigurationError.new("missing feishu oauth config"))

    post "/t/acme/integration_guides/feishu_oauth_authorization"

    assert_response :redirect
    assert_redirected_to "/t/acme/integration_guides/feishu"
  end
end
