require "test_helper"

class TenantFeishuAppConfigurationsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tenant = create(:tenant, :acme)
    @user = create(:tenant_user, :alice, tenant: @tenant)
    sign_in_tenant_user(tenant_uid: @tenant.uid, name: @user.name)
  end

  test "edit renders feishu app configuration form" do
    get "/t/acme/integration_guides/feishu_app_configuration/edit"

    assert_response :success
    assert_includes response.body, "feishu_enterprise[app_id]"
    assert_includes response.body, "feishu_enterprise[app_secret]"
  end

  test "update redirects to feishu guide and writes audit log" do
    assert_difference "AuditLog.count", +1 do
      patch "/t/acme/integration_guides/feishu_app_configuration", params: {
        feishu_enterprise: {
          app_id: "cli_acme",
          app_secret: "secret_acme",
          app_verification_token: "verify_acme",
          app_encrypt_key: "encrypt_acme"
        }
      }
    end

    assert_response :redirect
    assert_redirected_to "/t/acme/integration_guides/feishu"
  end

  test "update persists tenant feishu app settings" do
    patch "/t/acme/integration_guides/feishu_app_configuration", params: {
      feishu_enterprise: {
        app_id: "cli_acme",
        app_secret: "secret_acme",
        app_verification_token: "verify_acme",
        app_encrypt_key: "encrypt_acme"
      }
    }

    enterprise = FeishuEnterprise.find_by!(tenant: @tenant)

    assert_equal "cli_acme", enterprise.app_id
    assert_equal "secret_acme", enterprise.app_secret
    assert_equal "verify_acme", enterprise.app_verification_token
    assert_equal "encrypt_acme", enterprise.app_encrypt_key
  end
end
