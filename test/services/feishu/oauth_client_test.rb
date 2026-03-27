require "test_helper"
require "cgi"

module Feishu
  class OauthClientTest < ActiveSupport::TestCase
    def build_client
      OauthClient.new(
        oauth_base_uri: "https://open.feishu.cn",
        app_id: "cli_test",
        app_secret: "secret",
        redirect_uri: "https://dev-3000.dd-life.com/integrations/feishu/callback"
      )
    end

    test "authorization_url includes expected query params" do
      url = build_client.authorization_url(state: "state-1")

      assert_match "app_id=cli_test", url
      assert_match "state=state-1", url
      assert_match "redirect_uri=", url
    end

    test "exchange_code posts and parses token response" do
      response = Struct.new(:status, :body).new(200, '{"code":0,"data":{"access_token":"a1"}}')
      request = Struct.new(:headers, :body).new({}, nil)

      Faraday.expects(:post).with("https://open.feishu.cn/open-apis/authen/v2/oauth/token").yields(request).returns(response)

      token = build_client.exchange_code(code: "oauth-code")

      assert_equal "a1", token["access_token"]
      assert_equal "authorization_code", JSON.parse(request.body)["grant_type"]
    end

    test "exchange_code posts client credentials payload" do
      response = Struct.new(:status, :body).new(200, '{"code":0,"data":{"access_token":"a1"}}')
      request = Struct.new(:headers, :body).new({}, nil)

      Faraday.expects(:post).with("https://open.feishu.cn/open-apis/authen/v2/oauth/token").yields(request).returns(response)
      build_client.exchange_code(code: "oauth-code")

      body = JSON.parse(request.body)

      assert_equal "oauth-code", body["code"]
      assert_equal "cli_test", body["client_id"]
      assert_equal "secret", body["client_secret"]
      assert_equal "https://dev-3000.dd-life.com/integrations/feishu/callback", body["redirect_uri"]
    end

    test "user_info raises api error on failure" do
      response = Struct.new(:status, :body).new(401, '{"code":99991663,"msg":"invalid access token"}')
      request = Struct.new(:headers, :body).new({}, nil)

      Faraday.expects(:get).yields(request).returns(response)

      assert_raises(Feishu::ApiError) { build_client.user_info(access_token: "bad") }
    end

    test "test_connection posts tenant access token request" do
      response = Struct.new(:status, :body).new(200, '{"code":0,"tenant_access_token":"t1"}')
      request = Struct.new(:headers, :body).new({}, nil)

      Faraday.expects(:post).with("https://open.feishu.cn/open-apis/auth/v3/tenant_access_token/internal").yields(request).returns(response)

      result = build_client.test_connection
      body = JSON.parse(request.body)

      assert_equal "cli_test", body["app_id"]
      assert_equal "secret", body["app_secret"]
      assert_equal "t1", result["tenant_access_token"]
    end

    test "for_enterprise builds client from tenant settings" do
      tenant = create(:tenant, :acme)
      enterprise = create(
        :feishu_enterprise,
        tenant: tenant,
        app_id: "cli_acme",
        app_secret: "secret_acme"
      )

      client = OauthClient.for_enterprise!(
        enterprise: enterprise,
        redirect_uri_fallback: "https://example.com/integrations/feishu/callback"
      )
      url = client.authorization_url(state: "s1")
      expected_redirect_uri = ENV.fetch("feishu_oauth_redirect_uri", nil).presence || "https://example.com/integrations/feishu/callback"

      assert_match "app_id=cli_acme", url
      assert_match "redirect_uri=#{CGI.escape(expected_redirect_uri)}", url
    end
  end
end
