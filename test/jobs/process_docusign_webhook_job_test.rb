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

  test "updates envelope and contract status when webhook status is completed" do
    event, envelope, contract = build_completed_webhook_context

    ProcessDocusignWebhookJob.perform_now(event.id)

    event.reload
    envelope.reload
    contract.reload

    assert_equal "processed", event.status
    assert_equal "completed", envelope.status
    assert_equal "signed", contract.status
  end

  test "fills completed timestamps when webhook status is completed" do
    event, envelope, contract = build_completed_webhook_context

    ProcessDocusignWebhookJob.perform_now(event.id)

    envelope.reload
    contract.reload

    assert_predicate envelope.completed_at, :present?
    assert_predicate envelope.last_synced_at, :present?
    assert_predicate contract.completed_at, :present?
  end

  test "uses payload fallback for envelope id and maps delivered status" do
    tenant = create(:tenant, :acme)
    tenant_user = create(:tenant_user, :alice, tenant: tenant)
    connection = create(:tenant_docusign_connection, :acme_connection, tenant: tenant, connected_by_tenant_user: tenant_user)
    contract = create(:contract, :acme_contract, tenant: tenant, creator_tenant_user: tenant_user, status: "sent")
    envelope = create(:contract_envelope, contract: contract, tenant_docusign_connection: connection, envelope_id: "env-state-002", status: "sent")
    event = create(
      :webhook_event,
      tenant: tenant,
      status: "received",
      event_type: nil,
      external_event_id: nil,
      payload: {
        "eventType" => "envelope-delivered",
        "data" => {
          "envelopeSummary" => {
            "envelopeId" => envelope.envelope_id,
            "status" => "delivered"
          }
        }
      }
    )

    ProcessDocusignWebhookJob.perform_now(event.id)

    envelope.reload
    contract.reload

    assert_equal "delivered", envelope.status
    assert_equal "delivered", contract.status
    assert_predicate envelope.last_synced_at, :present?
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

  private

    def build_completed_webhook_context
      tenant = create(:tenant, :acme)
      tenant_user = create(:tenant_user, :alice, tenant: tenant)
      connection = create(:tenant_docusign_connection, :acme_connection, tenant: tenant, connected_by_tenant_user: tenant_user)
      contract = create(:contract, :acme_contract, tenant: tenant, creator_tenant_user: tenant_user, status: "sent", sent_at: 2.hours.ago, completed_at: nil)
      envelope = create(:contract_envelope, contract: contract, tenant_docusign_connection: connection, envelope_id: "env-state-001", status: "sent", completed_at: nil)
      event = create(:webhook_event, tenant: tenant, status: "received", event_type: "envelope-completed", external_event_id: envelope.envelope_id)
      [event, envelope, contract]
    end
end
