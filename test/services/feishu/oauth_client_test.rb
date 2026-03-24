require "test_helper"

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
  end
end
