require "test_helper"

class TenantDocusignConnectionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @acme_tenant = create(:tenant, :acme)
    @acme_user = create(:tenant_user, :alice, tenant: @acme_tenant)
    @acme_connection = create(:tenant_docusign_connection, :acme_connection, tenant: @acme_tenant, connected_by_tenant_user: @acme_user)

    @beta_tenant = create(:tenant, :beta)
    @beta_user = create(:tenant_user, :bob, tenant: @beta_tenant)
  end

  test "show returns connected state" do
    sign_in_tenant_user(tenant_uid: @acme_tenant.uid, name: @acme_user.name)

    get "/t/acme/docusign_connection.json"

    assert_response :success
    assert json_body["connected"]
    assert_equal "acct_acme", json_body["docusign_account_id"]
  end

  test "show returns disconnected when absent" do
    sign_in_tenant_user(tenant_uid: @beta_tenant.uid, name: @beta_user.name)

    get "/t/beta/docusign_connection.json"

    assert_response :success
    refute json_body["connected"]
  end

  test "authorize_url returns signed state and oauth url" do
    sign_in_tenant_user(tenant_uid: @acme_tenant.uid, name: @acme_user.name)

    fake_client = Class.new do
      attr_reader :state, :scope

      def authorization_url(state:, scope:)
        @state = state
        @scope = scope
        "https://account.example.com/oauth/auth"
      end
    end.new

    Docusign::OauthClient.stubs(:new).returns(fake_client)

    assert_difference "AuditLog.count", +1 do
      post "/t/acme/docusign_connection/oauth_authorization.json"
    end

    assert_response :success
    assert_equal "https://account.example.com/oauth/auth", json_body["authorize_url"]
    assert_equal "signature", fake_client.scope
    assert_predicate fake_client.state, :present?
  end

  test "authorize_url html redirects to docusign authorize page" do
    sign_in_tenant_user(tenant_uid: @acme_tenant.uid, name: @acme_user.name)

    fake_client = Class.new do
      attr_reader :state, :scope

      def authorization_url(state:, scope:)
        @state = state
        @scope = scope
        "https://account.example.com/oauth/auth"
      end
    end.new

    Docusign::OauthClient.stubs(:new).returns(fake_client)

    post "/t/acme/docusign_connection/oauth_authorization", params: {
      scopes: ["signature", "impersonation"]
    }

    assert_response :redirect
    assert_redirected_to "https://account.example.com/oauth/auth"
    assert_equal "signature impersonation", fake_client.scope
    assert_predicate fake_client.state, :present?
  end

  test "show html stays summary and oauth-first without create configuration link" do
    sign_in_tenant_user(tenant_uid: @beta_tenant.uid, name: @beta_user.name)

    get "/t/beta/docusign_connection"

    assert_response :success
    assert_no_match('name="tenant_docusign_connection[docusign_account_id]"', response.body)
    assert_no_match(%r{/t/beta/docusign_connection/new}, response.body)
    assert_match(%r{/t/beta/docusign_connection/oauth_authorization}, response.body)
  end

  test "edit shows readonly account fields for connected tenant" do
    sign_in_tenant_user(tenant_uid: @acme_tenant.uid, name: @acme_user.name)

    get "/t/acme/docusign_connection/edit"

    assert_response :success
    assert_match("acct_acme", response.body)
    assert_no_match('name="tenant_docusign_connection[docusign_account_id]"', response.body)
  end

  test "edit redirects to show when connection missing" do
    sign_in_tenant_user(tenant_uid: @beta_tenant.uid, name: @beta_user.name)

    get "/t/beta/docusign_connection/edit"

    assert_response :redirect
    assert_redirected_to "/t/beta/docusign_connection"
  end

  test "update ignores account id and base uri updates" do
    sign_in_tenant_user(tenant_uid: @acme_tenant.uid, name: @acme_user.name)

    patch "/t/acme/docusign_connection.json", params: {
      tenant_docusign_connection: {
        docusign_account_id: "acct_hacked",
        docusign_base_uri: "https://example.com/restapi",
        oauth_scope: "signature impersonation"
      }
    }

    @acme_connection.reload

    assert_response :success
    assert_equal "signature impersonation", json_body["oauth_scope"]
    assert_equal "acct_acme", @acme_connection.docusign_account_id
    assert_equal "https://demo.docusign.net/restapi", @acme_connection.docusign_base_uri
  end
end
