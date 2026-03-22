require "test_helper"

class IntegrationsDocusignOauthCallbacksControllerTest < ActionDispatch::IntegrationTest
  setup do
    @tenant = create(:tenant, :acme)
    @tenant_user = create(:tenant_user, :alice, tenant: @tenant)
    @connection = create(:tenant_docusign_connection, :acme_connection, tenant: @tenant, connected_by_tenant_user: @tenant_user)
  end

  test "renders html authorization failure when docusign sends error" do
    get "/integrations/docusign/oauth/callback", params: {
      error: "access_denied",
      error_description: "user denied"
    }

    assert_response :unprocessable_entity
    assert_includes response.body, "DocuSign"
    assert_includes response.body, "user denied"
  end

  test "returns json authorization failure payload when requested as json" do
    get "/integrations/docusign/oauth/callback", params: {
      error: "access_denied",
      error_description: "user denied"
    }, as: :json

    assert_response :unprocessable_entity
    assert_equal "docusign_authorization_failed", json_body["error"]
  end

  test "renders html callback result page on success" do
    state = Docusign::OauthState.generate(tenant_uid: @tenant.uid, return_to: "/after-connect")

    Docusign::OauthClient.stubs(:new).returns(fake_oauth_client)
    assert_difference "AuditLog.count", +1 do
      get "/integrations/docusign/oauth/callback", params: {
        state: state,
        code: "oauth-code"
      }
    end

    assert_response :success
    assert_includes response.body, "DocuSign"
    assert_includes response.body, @tenant.uid
    assert_includes response.body, "/after-connect"

    @connection.reload

    assert_equal "access_new", @connection.access_token
    assert_equal "refresh_new", @connection.refresh_token
    assert_equal "https://demo.docusign.net/restapi", @connection.docusign_base_uri
  end

  test "returns json payload on success when requested as json" do
    state = Docusign::OauthState.generate(tenant_uid: @tenant.uid, return_to: "/after-connect")

    Docusign::OauthClient.stubs(:new).returns(fake_oauth_client)
    assert_difference "AuditLog.count", +1 do
      get "/integrations/docusign/oauth/callback", params: {
        state: state,
        code: "oauth-code"
      }, as: :json
    end

    assert_response :success
    assert_equal @tenant.uid, json_body["tenant_uid"]
    assert_equal "acct_acme", json_body["connection"]["docusign_account_id"]
    assert_equal "/after-connect", json_body["return_to"]
  end

  test "does not sign in browser session from oauth state tenant_user_id" do
    state = Docusign::OauthState.generate(
      tenant_uid: @tenant.uid,
      tenant_user_id: @tenant_user.id,
      return_to: "/after-connect"
    )

    Docusign::OauthClient.stubs(:new).returns(fake_oauth_client)

    get "/integrations/docusign/oauth/callback", params: {
      state: state,
      code: "oauth-code"
    }

    assert_response :success

    get "/t/acme/dashboard"

    assert_response :redirect
    assert_includes response.location, "/tenant_auth/iam/sign_in"
  end

  test "uses admin layout when browser already signed in to the same tenant" do
    sign_in_tenant_user(tenant_uid: @tenant.uid, name: @tenant_user.name)
    state = Docusign::OauthState.generate(tenant_uid: @tenant.uid, return_to: "/after-connect")

    Docusign::OauthClient.stubs(:new).returns(fake_oauth_client)

    get "/integrations/docusign/oauth/callback", params: {
      state: state,
      code: "oauth-code"
    }

    assert_response :success
    assert_includes response.body, 'class="sidebar"'
    assert_includes response.body, "DocuSign 业务"
  end

  test "returns unauthorized for invalid state" do
    get "/integrations/docusign/oauth/callback", params: {
      state: "invalid",
      code: "oauth-code"
    }

    assert_response :unauthorized
    assert_includes response.body, "DocuSign"
  end

  private

    def fake_oauth_client
      fake_client = Object.new
      fake_client.define_singleton_method(:exchange_code) do |code:|
        raise "unexpected code" unless code == "oauth-code"

        {
          "access_token" => "access_new",
          "refresh_token" => "refresh_new",
          "expires_in" => 7200,
          "scope" => "signature"
        }
      end

      fake_client.define_singleton_method(:user_info) do |access_token:|
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

      fake_client
    end
end
