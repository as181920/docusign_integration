require "digest"

module Webhooks
  class DocusignController < ActionController::API
    before_action :validate_signature!

    def create
      payload_text = request.raw_post
      payload = Docusign::WebhookPayloadParser.call(payload_text)
      account_id = payload.dig("data", "accountId") || payload["accountId"]
      envelope_id = payload.dig("data", "envelopeId") || payload.dig("data", "envelopeSummary", "envelopeId")
      event_type = payload["event"] || payload["eventType"]
      delivery_id = request.headers["X-DocuSign-Delivery-ID"].presence || default_delivery_id(payload)

      connection = TenantDocusignConnection.find_by(docusign_account_id: account_id)
      webhook_event = find_or_create_webhook_event(
        delivery_id: delivery_id,
        event_type: event_type,
        envelope_id: envelope_id,
        account_id: account_id,
        tenant_id: connection&.tenant_id,
        payload: payload
      )

      if webhook_event.received?
        ProcessDocusignWebhookJob.perform_later(webhook_event.id)
        Rails.logger.info(
          "[DocusignWebhook] accepted delivery_id=#{delivery_id} event=#{event_type} envelope_id=#{envelope_id} tenant_id=#{connection&.tenant_id} webhook_event_id=#{webhook_event.id}"
        )
      else
        Rails.logger.info(
          "[DocusignWebhook] duplicate delivery_id=#{delivery_id} status=#{webhook_event.status} webhook_event_id=#{webhook_event.id}"
        )
      end

      head :accepted
    rescue ActiveRecord::RecordInvalid => e
      Rails.logger.error("[DocusignWebhook] persist failed error=#{e.record.errors.full_messages.to_sentence}")
      render json: { error: e.record.errors.full_messages.to_sentence }, status: :unprocessable_entity
    end

    private

      def find_or_create_webhook_event(delivery_id:, event_type:, envelope_id:, account_id:, tenant_id:, payload:)
        event = WebhookEvent.find_or_initialize_by(provider: "docusign", delivery_id: delivery_id)
        return event if event.persisted?

        event.assign_attributes(
          tenant_id: tenant_id,
          event_type: event_type,
          external_account_id: account_id,
          external_event_id: envelope_id,
          received_at: Time.current,
          headers: tracked_headers,
          payload: payload,
          status: :received
        )
        event.save!
        event
      rescue ActiveRecord::RecordNotUnique
        WebhookEvent.find_by!(provider: "docusign", delivery_id: delivery_id)
      end

      def tracked_headers
        request.headers.to_h.select do |key, _value|
          key.start_with?("HTTP_X_DOCUSIGN_") || key == "CONTENT_TYPE" || key == "HTTP_USER_AGENT"
        end
      end

      def validate_signature!
        payload_text = request.raw_post
        signature = request.headers["X-DocuSign-Signature-1"]
        secret = ENV.fetch("docusign_connect_hmac_secret", nil)

        return if Docusign::WebhookSignatureVerifier.valid?(payload: payload_text, signature: signature, secret: secret)

        Rails.logger.warn("[DocusignWebhook] signature validation failed")
        head :unauthorized
      end

      def default_delivery_id(payload)
        [
          payload["event"],
          payload.dig("data", "envelopeId"),
          payload.dig("data", "eventTimestamp"),
          Digest::SHA256.hexdigest(payload.to_json)
        ].compact.join(":")
      end
  end
end
