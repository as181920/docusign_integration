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

      Faraday.expects(:post).yields(request).returns(response)

      token = build_client.exchange_code(code: "oauth-code")

      assert_equal "a1", token["access_token"]
    end

    test "user_info raises api error on failure" do
      response = Struct.new(:status, :body).new(401, '{"code":99991663,"msg":"invalid access token"}')
      request = Struct.new(:headers, :body).new({}, nil)

      Faraday.expects(:get).yields(request).returns(response)

      assert_raises(Feishu::ApiError) { build_client.user_info(access_token: "bad") }
    end
  end
end
