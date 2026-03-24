require "test_helper"
require "openssl"

class IntegrationsFeishuEventsControllerTest < ActionDispatch::IntegrationTest
  test "challenge returns challenge payload directly" do
    with_env("feishu_app_verification_token" => "verify-token") do
      assert_no_difference "AuditLog.count" do
        post "/integrations/feishu/events", params: { challenge: "abc123", token: "verify-token" }
      end
    end

    assert_response :success
    assert_equal "abc123", json_body["challenge"]
  end

  test "challenge returns unauthorized when token invalid" do
    with_env("feishu_app_verification_token" => "verify-token") do
      post "/integrations/feishu/events", params: { challenge: "abc123", token: "wrong-token" }
    end

    assert_response :unauthorized
  end

  test "event payload is accepted and audited when signature is valid" do
    with_env("feishu_app_verification_token" => "", "feishu_app_encrypt_key" => "encrypt-key") do
      body = { event: { type: "app_ticket" } }.to_json
      timestamp = "1774329600"
      nonce = "nonce-1"
      signature = OpenSSL::Digest::SHA256.hexdigest("#{timestamp}#{nonce}encrypt-key#{body}")

      assert_difference "AuditLog.count", +1 do
        post "/integrations/feishu/events",
             params: body,
             headers: {
               "CONTENT_TYPE" => "application/json",
               "HTTP_X_LARK_REQUEST_TIMESTAMP" => timestamp,
               "HTTP_X_LARK_REQUEST_NONCE" => nonce,
               "HTTP_X_LARK_SIGNATURE" => signature
             }
      end
    end

    assert_response :success
  end

  test "event payload is rejected when signature invalid" do
    with_env("feishu_app_verification_token" => "", "feishu_app_encrypt_key" => "encrypt-key") do
      body = { event: { type: "app_ticket" } }.to_json

      assert_no_difference "AuditLog.count" do
        post "/integrations/feishu/events",
             params: body,
             headers: {
               "CONTENT_TYPE" => "application/json",
               "HTTP_X_LARK_REQUEST_TIMESTAMP" => "1774329600",
               "HTTP_X_LARK_REQUEST_NONCE" => "nonce-1",
               "HTTP_X_LARK_SIGNATURE" => "invalid-signature"
             }
      end
    end

    assert_response :unauthorized
  end
end
