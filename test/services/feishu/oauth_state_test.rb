require "test_helper"

module Feishu
  class OauthStateTest < ActiveSupport::TestCase
    test "generate and verify returns expected payload" do
      token = OauthState.generate(tenant_uid: "acme", tenant_user_id: 123, return_to: "/t/acme/dashboard")
      payload = OauthState.verify(token)

      assert_equal "acme", payload["tenant_uid"]
      assert_equal 123, payload["tenant_user_id"]
      assert_equal "/t/acme/dashboard", payload["return_to"]
      assert_predicate payload["issued_at"], :present?
    end

    test "verify invalid state raises oauth_state_error" do
      error = assert_raises(Feishu::OauthStateError) { OauthState.verify("invalid") }
      assert_match "invalid feishu oauth state", error.message
    end
  end
end
