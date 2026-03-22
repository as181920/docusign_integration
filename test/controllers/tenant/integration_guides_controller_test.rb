require "test_helper"

class TenantIntegrationGuidesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tenant = create(:tenant, :acme)
    @user = create(:tenant_user, :alice, tenant: @tenant)
    sign_in_tenant_user(tenant_uid: @tenant.uid, name: @user.name)
  end

  test "feishu guide renders setup steps and callback endpoints" do
    get "/t/acme/integration_guides/feishu"

    assert_response :success
    assert_select "h1", text: "飞书 Web 集成配置说明"
    assert_includes response.body, "/integrations/feishu/callback"
    assert_includes response.body, "/integrations/feishu/events"
    assert_includes response.body, "tenant_uid"
  end

  test "feishu guide hides internal config keys and shows system entry" do
    get "/t/acme/integration_guides/feishu"

    assert_response :success
    refute_includes response.body, "feishu_app_id"
    assert_includes response.body, "/t/acme/dashboard"
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
