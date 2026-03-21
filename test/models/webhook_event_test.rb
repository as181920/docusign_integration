require "test_helper"

class WebhookEventTest < ActiveSupport::TestCase
  test "factory is valid" do
    assert_predicate build(:webhook_event), :valid?
  end

  test "requires delivery_id" do
    event = WebhookEvent.new

    assert_not event.valid?
    assert event.errors.of_kind?(:delivery_id, :blank)
  end

  test "enforces provider scoped delivery_id uniqueness" do
    existing = create(:webhook_event, provider: "docusign", delivery_id: "delivery-1")

    duplicate = WebhookEvent.new(
      provider: existing.provider,
      delivery_id: existing.delivery_id
    )

    assert_not duplicate.valid?
    assert duplicate.errors.of_kind?(:delivery_id, :taken)
  end
end
