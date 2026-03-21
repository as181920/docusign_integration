require "test_helper"

class OutboundEventTest < ActiveSupport::TestCase
  test "factory is valid" do
    assert_predicate build(:outbound_event), :valid?
  end

  test "requires event_name" do
    event = OutboundEvent.new

    assert_not event.valid?
    assert event.errors.of_kind?(:event_name, :blank)
  end

  test "default status is pending" do
    event = OutboundEvent.new(event_name: "contract.sent")

    assert_equal "pending", event.status
  end
end
