require "test_helper"

class IntegrationsDocusignOauthCallbacksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tenant = create(:tenant, :acme)
    @tenant_user = create(:tenant_user, :alice, tenant: @tenant)
    @connection = create(:tenant_docusign_connection, :acme_connection, tenant: @tenant, connected_by_tenant_user: @tenant_user)
  end

  test "returns authorization failure payload when docusign sends error" do
    get "/integrations/docusign/oauth/callback", params: {
      error: "access_denied",
      error_description: "user denied"
    }

    assert_response :unprocessable_entity
    assert_equal "docusign_authorization_failed", json_body["error"]
  end

  test "connects tenant docusign account on success" do
    state = Docusign::OauthState.generate(tenant_uid: @tenant.uid, return_to: "/after-connect")

    fake_client = Object.new
    fake_client.define_singleton_method(:exchange_code!) do |code:|
      raise "unexpected code" unless code == "oauth-code"

      {
        "access_token" => "access_new",
        "refresh_token" => "refresh_new",
        "expires_in" => 7200,
        "scope" => "signature"
      }
    end

    fake_client.define_singleton_method(:user_info!) do |access_token:|
      raise "unexpected access token" unless access_token == "access_new"

      {
        "sub" => "user_sub",
        "name" => "Doc User",
        "email" => "doc@example.com",
        "accounts" => [
          {
            "account_id" => "acct_acme",
            "account_name" => "ACME DS",
            "is_default" => true,
            "base_uri" => "https://demo.docusign.net"
          }
        ]
      }
    end

    Docusign::OauthClient.stubs(:new).returns(fake_client)
    assert_difference "AuditLog.count", +1 do
      get "/integrations/docusign/oauth/callback", params: {
        state: state,
        code: "oauth-code"
      }
    end

    assert_response :success
    assert_equal @tenant.uid, json_body["tenant_uid"]
    assert_equal "acct_acme", json_body["connection"]["docusign_account_id"]

    @connection.reload

    assert_equal "access_new", @connection.access_token
    assert_equal "refresh_new", @connection.refresh_token
    assert_equal "https://demo.docusign.net/restapi", @connection.docusign_base_uri
  end

  test "returns unauthorized for invalid state" do
    get "/integrations/docusign/oauth/callback", params: {
      state: "invalid",
      code: "oauth-code"
    }

    assert_response :unauthorized
  end
end
