require "test_helper"

class WelcomeControllerTest < ActionDispatch::IntegrationTest
  test "root renders redesigned welcome page with enterprise sign in entry" do
    get root_path

    assert_response :success
    assert_select "h1", text: "合同管理中台"
    assert_select "a", text: "企业登录"
  end

  test "root includes tenant-aware sign in url params" do
    get root_path

    assert_response :success
    assert_includes response.body, "/tenant_auth/iam/sign_in"
    assert_includes response.body, "tenant_uid=demo"
    assert_includes response.body, "redirect_url=%2Ft%2Fdemo%2Fdashboard"
  end

  test "root does not append locale param when locale comes from browser header" do
    get root_path, headers: { "Accept-Language" => "en-US,en;q=0.9" }

    assert_response :success
    assert_includes response.body, "redirect_url=%2Ft%2Fdemo%2Fdashboard"
    assert_no_match(/locale=en/, response.body)
  end

  test "root shows dashboard button when tenant user exists in session context" do
    tenant = create(:tenant, :acme)
    user = create(:tenant_user, :alice, tenant: tenant)

    relation = mock("tenant_user_relation")
    relation.stubs(:find_by).returns(user)
    TenantAuth::User.stubs(:includes).with(:tenant).returns(relation)

    get root_path

    assert_response :success
    assert_select "a", text: "进入控制台"
    assert_select "a[href='/t/acme/dashboard']", text: "进入控制台"
    assert_no_match("/tenant_auth/iam/sign_in", response.body)
  end

  test "root renders english content when locale is en" do
    get root_path, params: { locale: "en" }

    assert_response :success
    assert_select "h1", text: "Contract Management Hub"
    assert_select "a", text: "Enterprise Sign In"
  end
end
