require "test_helper"

class ProcessDocusignWebhookJobTest < ActiveJob::TestCase
  test "marks webhook event processed" do
    event = create(:webhook_event, status: "received", processing_attempts: 0)

    ProcessDocusignWebhookJob.perform_now(event.id)

    event.reload

    assert_equal "processed", event.status
    assert_predicate event.processed_at, :present?
    assert_equal 1, event.processing_attempts
  end

  test "marks webhook event failed and raises when update fails" do
    event = create(:webhook_event, status: "received", processing_attempts: 0)

    WebhookEvent.stubs(:find).with(event.id).returns(event)
    event.stubs(:update!).raises(RuntimeError.new("force-fail"))

    assert_raises(RuntimeError) { ProcessDocusignWebhookJob.perform_now(event.id) }

    event.reload

    assert_equal "failed", event.status
    assert_match "RuntimeError", event.last_error
  end
end
