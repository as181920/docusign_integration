require "test_helper"

class TenantDashboardsControllerTest < ActionDispatch::IntegrationTest
  test "show returns tenant summary in json" do
    tenant = create(:tenant, :acme)
    user = create(:tenant_user, :alice, tenant: tenant)
    sign_in_tenant_user(tenant_uid: tenant.uid, name: user.name)

    get "/t/acme/dashboard.json"

    assert_response :success
    assert_equal "acme", json_body["tenant_uid"]
    assert_equal "ACME Tenant", json_body["tenant_name"]
  end

  test "show renders dashboard business navigation" do
    tenant = create(:tenant, :acme)
    user = create(:tenant_user, :alice, tenant: tenant)
    sign_in_tenant_user(tenant_uid: tenant.uid, name: user.name)

    get "/t/acme/dashboard"

    assert_response :success
    assert_select "h1", text: "欢迎使用 DocuSign 企业后台"
    assert_select "a", text: "DocuSign 连接"
    assert_select "a", text: "合同模板"
    assert_select "a", text: "合同列表"
    assert_select "a", text: "Webhook 事件"
    assert_select "a", text: "平台集成"
    assert_select "a", text: "飞书配置说明"
  end

  test "show respects explicit locale param over user preference" do
    tenant = create(:tenant, :acme)
    user = create(:tenant_user, :alice, tenant: tenant)
    sign_in_tenant_user(tenant_uid: tenant.uid, name: user.name)

    get "/t/acme/dashboard", params: { locale: "en" }

    assert_response :success
    assert_select "h1", text: "Welcome to the DocuSign Enterprise Console"
  end

  test "show renders profile menu and hides session copy" do
    tenant = create(:tenant, :acme)
    user = create(:tenant_user, :alice, tenant: tenant)
    sign_in_tenant_user(tenant_uid: tenant.uid, name: user.name)

    get "/t/acme/dashboard"

    assert_response :success
    assert_select ".profile-settings", 1
    assert_select "a", text: "个人信息"
    assert_select "a", text: "退出登录"
    assert_no_match("会话管理", response.body)
  end
end
