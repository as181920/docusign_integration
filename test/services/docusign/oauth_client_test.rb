require "test_helper"

module Docusign
  class OauthClientTest < ActiveSupport::TestCase
    def build_client
      OauthClient.new(
        oauth_base_uri: "https://account-d.docusign.com",
        integration_key: "integration-key",
        client_secret: "secret",
        redirect_uri: "https://app.example.com/integrations/docusign/oauth/callback"
      )
    end

    test "authorization_url includes expected query params" do
      url = build_client.authorization_url(state: "state-1", scope: "signature impersonation")

      assert_match "response_type=code", url
      assert_match "client_id=integration-key", url
      assert_match "state=state-1", url
      assert_match "scope=signature+impersonation", url
    end

    test "exchange_code posts and parses token response" do
      response = Struct.new(:status, :body).new(200, '{"access_token":"a1","refresh_token":"r1","expires_in":3600}')
      req = Struct.new(:headers, :body).new({}, nil)

      Faraday.expects(:post).yields(req).returns(response)

      token = build_client.exchange_code!(code: "oauth-code")

      assert_equal "a1", token["access_token"]
    end

    test "user_info raises api error on failure" do
      response = Struct.new(:status, :body).new(401, '{"error":"unauthorized"}')
      req = Struct.new(:headers, :body).new({}, nil)

      Faraday.expects(:get).yields(req).returns(response)

      assert_raises(Docusign::ApiError) { build_client.user_info!(access_token: "bad") }
    end
  end
end
