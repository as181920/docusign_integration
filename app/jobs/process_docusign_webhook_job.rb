class ProcessDocusignWebhookJob < ApplicationJob
  queue_as :default

  def perform(webhook_event_id)
    webhook_event = WebhookEvent.find(webhook_event_id)

    webhook_event.with_lock do
      webhook_event.processing_attempts += 1
      webhook_event.status = :processing
      webhook_event.last_error = nil
      webhook_event.save!
    end

    Rails.logger.info(
      "[DocusignWebhook] processing webhook_event_id=#{webhook_event.id} delivery_id=#{webhook_event.delivery_id} " \
      "event=#{webhook_event.event_type} envelope_id=#{webhook_event.external_event_id} account_id=#{webhook_event.external_account_id} " \
      "tenant_id=#{webhook_event.tenant_id}"
    )

    Rails.logger.info("[DocusignWebhook] payload=#{webhook_event.payload.to_json}")

    webhook_event.update!(status: :processed, processed_at: Time.current)
  rescue StandardError => e
    webhook_event&.update_columns(status: "failed", last_error: "#{e.class}: #{e.message}")
    Rails.logger.error(
      "[DocusignWebhook] failed webhook_event_id=#{webhook_event&.id} delivery_id=#{webhook_event&.delivery_id} error=#{e.class}: #{e.message}"
    )
    raise
  end
end
