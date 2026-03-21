require "test_helper"

module Docusign
  class TokenManagerTest < ActiveSupport::TestCase
    def create_connection
      tenant = create(:tenant, :acme)
      tenant_user = create(:tenant_user, :alice, tenant: tenant)
      create(:tenant_docusign_connection, :acme_connection, tenant: tenant, connected_by_tenant_user: tenant_user)
    end

    test "current_access_token returns existing token when not near expiry" do
      connection = create_connection
      connection.update!(access_token: "existing", token_expires_at: 10.minutes.from_now)

      assert_equal "existing", TokenManager.current_access_token!(connection)
    end

    test "current_access_token refreshes when token near expiry" do
      connection = create_connection
      connection.update!(access_token: "old", token_expires_at: 30.seconds.from_now)

      TokenManager.stubs(:refresh_access_token!).returns("new-token")

      assert_equal "new-token", TokenManager.current_access_token!(connection)
    end

    test "refresh_access_token requires refresh_token" do
      connection = create_connection
      connection.update!(refresh_token: nil)

      assert_raises(Docusign::ConfigurationError) { TokenManager.refresh_access_token!(connection) }
    end

    test "refresh_access_token updates connection from oauth response" do
      connection = create_connection
      called_with = nil

      fake_client = Object.new
      fake_client.define_singleton_method(:refresh_token!) do |refresh_token:|
        called_with = refresh_token
        {
          "access_token" => "new-access",
          "refresh_token" => "new-refresh",
          "expires_in" => 3600
        }
      end

      OauthClient.stubs(:new).returns(fake_client)
      token = TokenManager.refresh_access_token!(connection)

      assert_equal "new-access", token

      connection.reload

      assert_equal "new-refresh", connection.refresh_token
      assert_equal "new-access", connection.access_token
      assert_predicate connection, :active?
      assert_equal "refresh_token_acme", called_with
    end

    test "refresh_access_token marks connection expired when refresh fails" do
      connection = create_connection

      fake_client = Object.new
      fake_client.define_singleton_method(:refresh_token!) do |refresh_token:|
        raise Docusign::ApiError, "boom"
      end

      OauthClient.stubs(:new).returns(fake_client)
      assert_raises(Docusign::ApiError) { TokenManager.refresh_access_token!(connection) }

      assert_predicate connection.reload, :expired?
    end
  end
end
