require "test_helper"

class RansackAllowlistTest < ActiveSupport::TestCase
  test "contract searches cannot traverse tenant associations" do
    assert_raises Ransack::InvalidSearchError do
      Contract.ransack!(tenant_name_cont: SecureRandom.hex)
    end
  end

  test "webhook searches cannot access raw payloads" do
    assert_raises Ransack::InvalidSearchError do
      WebhookEvent.ransack!(payload_cont: SecureRandom.hex)
    end
  end

  test "unqueried connection models do not expose credentials for searching" do
    assert_raises RuntimeError do
      TenantDocusignConnection.ransack!(access_token_eq: SecureRandom.hex)
    end
  end
end
