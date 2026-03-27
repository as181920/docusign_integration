require "test_helper"

class TenantIntegrationGuidesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tenant = create(:tenant, :acme)
    @user = create(:tenant_user, :alice, tenant: @tenant)
    sign_in_tenant_user(tenant_uid: @tenant.uid, name: @user.name)
  end

  test "feishu guide renders tenant app settings summary" do
    get "/t/acme/integration_guides/feishu"

    assert_response :success
    assert_select "h1", text: "飞书 Web 集成配置说明"
    assert_includes response.body, "企业飞书应用配置"
    assert_includes response.body, "未配置"
  end

  test "feishu guide renders feishu endpoints" do
    get "/t/acme/integration_guides/feishu"

    assert_response :success
    assert_includes response.body, "/integrations/feishu/entry?tenant_uid=acme"
    assert_includes response.body, "/integrations/feishu/callback"
    assert_includes response.body, "/integrations/feishu/events"
  end

  test "feishu guide includes oauth action and tenant config actions" do
    get "/t/acme/integration_guides/feishu"

    assert_response :success
    assert_includes response.body, "/t/acme/integration_guides/feishu_app_configuration/edit"
    assert_includes response.body, "/t/acme/integration_guides/feishu_connection_test"
    assert_includes response.body, "/t/acme/integration_guides/feishu_oauth_authorization"
  end

  test "sap guide is placeholder" do
    get "/t/acme/integration_guides/sap"

    assert_response :success
    assert_select "h1", text: "SAP 集成配置说明"
    assert_includes response.body, "敬请期待"
  end

  test "fanwei guide is placeholder" do
    get "/t/acme/integration_guides/fanwei"

    assert_response :success
    assert_select "h1", text: "泛微集成配置说明"
    assert_includes response.body, "敬请期待"
  end
end
