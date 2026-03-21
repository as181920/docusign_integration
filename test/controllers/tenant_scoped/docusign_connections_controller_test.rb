require "test_helper"

class TenantScopedDocusignConnectionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @acme_tenant = create(:tenant, :acme)
    @acme_user = create(:tenant_user, :alice, tenant: @acme_tenant)
    create(:tenant_docusign_connection, :acme_connection, tenant: @acme_tenant, connected_by_tenant_user: @acme_user)

    @beta_tenant = create(:tenant, :beta)
    @beta_user = create(:tenant_user, :bob, tenant: @beta_tenant)
  end

  test "show returns connected state" do
    get "/t/acme/docusign_connection"

    assert_response :success
    assert json_body["connected"]
    assert_equal "acct_acme", json_body["docusign_account_id"]
  end

  test "show returns disconnected when absent" do
    get "/t/beta/docusign_connection"

    assert_response :success
    refute json_body["connected"]
  end

  test "authorize_url returns signed state and oauth url" do
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
      get "/t/acme/docusign_connection/authorize_url"
    end

    assert_response :success
    assert_equal "https://account.example.com/oauth/auth", json_body["authorize_url"]
    assert_equal "signature", fake_client.scope
    assert_predicate fake_client.state, :present?
  end

  test "create builds connection" do
    assert_difference ["TenantDocusignConnection.count", "AuditLog.count"], +1 do
      post "/t/beta/docusign_connection", params: {
        tenant_docusign_connection: {
          docusign_account_id: "acct_beta_new",
          docusign_base_uri: "https://demo.docusign.net/restapi"
        }
      }
    end

    assert_response :created
    assert_equal "acct_beta_new", json_body["docusign_account_id"]
  end

  test "update changes connection attrs" do
    patch "/t/acme/docusign_connection", params: {
      tenant_docusign_connection: {
        oauth_scope: "signature impersonation"
      }
    }

    assert_response :success
    assert_equal "signature impersonation", json_body["oauth_scope"]
  end
end
