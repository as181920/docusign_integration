require "test_helper"

class TenantFeishuConnectionTestsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tenant = create(:tenant, :acme)
    @user = create(:tenant_user, :alice, tenant: @tenant)
    @enterprise = create(:feishu_enterprise, :acme_enterprise, tenant: @tenant, app_secret: "secret_acme")
    sign_in_tenant_user(tenant_uid: @tenant.uid, name: @user.name)
  end

  test "create tests connection and redirects back with success notice" do
    oauth_client = mock("feishu-oauth-client")
    Feishu::OauthClient.expects(:for_enterprise!).returns(oauth_client)
    oauth_client.expects(:test_connection).returns({ "tenant_access_token" => "token-1" })

    assert_difference "AuditLog.count", +1 do
      post "/t/acme/integration_guides/feishu_connection_test"
    end

    assert_response :redirect
    assert_redirected_to "/t/acme/integration_guides/feishu"
  end

  test "create redirects back with alert when config invalid" do
    Feishu::OauthClient.expects(:for_enterprise!).raises(Feishu::ConfigurationError.new("missing tenant feishu app config"))

    assert_difference "AuditLog.count", +1 do
      post "/t/acme/integration_guides/feishu_connection_test"
    end

    assert_response :redirect
    assert_redirected_to "/t/acme/integration_guides/feishu"
  end
end
