require "test_helper"

class WebhooksDocusignControllerTest < ActionDispatch::IntegrationTest
  setup do
    ActiveJob::Base.queue_adapter = :test
    clear_enqueued_jobs

    tenant = create(:tenant, :acme)
    tenant_user = create(:tenant_user, :alice, tenant: tenant)
    @connection = create(:tenant_docusign_connection, :acme_connection, tenant: tenant, connected_by_tenant_user: tenant_user)
    @processed_event = create(:webhook_event, tenant: tenant, provider: "docusign", delivery_id: "delivery-processed-001", status: "processed")
  end

  test "accepts webhook and enqueues processing job" do
    payload = {
      event: "envelope-completed",
      data: {
        accountId: @connection.docusign_account_id,
        envelopeId: "env_new_001",
        eventTimestamp: Time.current.iso8601
      }
    }.to_json

    headers = signed_headers(payload, delivery_id: "delivery-new-001")

    assert_difference "WebhookEvent.count", +1 do
      assert_enqueued_with(job: ProcessDocusignWebhookJob) do
        post "/webhooks/docusign", params: payload, headers: headers
      end
    end

    assert_response :accepted
  end

  test "does not enqueue duplicate delivery" do
    payload = {
      event: "envelope-completed",
      data: { accountId: @connection.docusign_account_id, envelopeId: "env_acme_001" }
    }.to_json

    headers = signed_headers(payload, delivery_id: @processed_event.delivery_id)

    assert_no_difference "WebhookEvent.count" do
      assert_no_enqueued_jobs do
        post "/webhooks/docusign", params: payload, headers: headers
      end
    end

    assert_response :accepted
  end

  test "returns unauthorized when signature invalid" do
    payload = { event: "envelope-completed", data: { accountId: @connection.docusign_account_id } }.to_json

    with_env("docusign_connect_hmac_secret" => "secret") do
      post "/webhooks/docusign", params: payload, headers: {
        "CONTENT_TYPE" => "application/json",
        "X-DocuSign-Signature-1" => "bad-signature"
      }
    end

    assert_response :unauthorized
  end

  private

    def signed_headers(payload, delivery_id:)
      headers = {
        "CONTENT_TYPE" => "application/json",
        "X-DocuSign-Delivery-ID" => delivery_id
      }

      secret = ENV.fetch("docusign_connect_hmac_secret", nil).to_s
      if secret.present?
        headers["X-DocuSign-Signature-1"] = Base64.strict_encode64(OpenSSL::HMAC.digest("SHA256", secret, payload))
      end

      headers
    end
end
