require "test_helper"

class TenantScopedDashboardsControllerTest < ActionDispatch::IntegrationTest
  test "show returns tenant summary" do
    create(:tenant, :acme)

    get "/t/acme/dashboard"

    assert_response :success
    assert_equal "acme", json_body["tenant_uid"]
    assert_equal "ACME Tenant", json_body["tenant_name"]
  end
end
