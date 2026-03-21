require "test_helper"

class IntegrationsFeishuEventsControllerTest < ActionDispatch::IntegrationTest
  test "challenge returns challenge payload directly" do
    assert_no_difference "AuditLog.count" do
      post "/integrations/feishu/events", params: { challenge: "abc123" }
    end

    assert_response :success
    assert_equal "abc123", json_body["challenge"]
  end

  test "event payload is accepted and audited" do
    assert_difference "AuditLog.count", +1 do
      post "/integrations/feishu/events", params: { event: { type: "app_ticket" } }
    end

    assert_response :success
  end
end
