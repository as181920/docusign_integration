module Docusign
  class WebhookStatusMapper
    class << self
      def call(webhook_event:)
        envelope_id = extract_envelope_id(webhook_event)
        return nil if envelope_id.blank?

        envelope = ContractEnvelope.includes(:contract).find_by(envelope_id: envelope_id)
        return nil if envelope.blank?

        envelope_status = normalize_status(webhook_event)
        return envelope if envelope_status.blank?

        now = Time.current
        update_envelope(envelope, envelope_status, now)
        update_contract(envelope.contract, envelope_status, now)
        envelope
      end

      private

        def extract_envelope_id(webhook_event)
          webhook_event.external_event_id.presence ||
            webhook_event.payload.dig("data", "envelopeId").presence ||
            webhook_event.payload.dig("data", "envelopeSummary", "envelopeId").presence
        end

        def normalize_status(webhook_event)
          candidates = [
            webhook_event.event_type,
            webhook_event.payload["event"],
            webhook_event.payload["eventType"],
            webhook_event.payload.dig("data", "envelopeSummary", "status"),
            webhook_event.payload.dig("data", "status"),
            webhook_event.payload["status"]
          ].compact.map { |value| value.to_s.downcase.strip }.reject(&:blank?)

          return "completed" if candidates.any? { |value| value.include?("complete") }
          return "delivered" if candidates.any? { |value| value.include?("deliver") }
          return "declined" if candidates.any? { |value| value.include?("declin") }
          return "voided" if candidates.any? { |value| value.include?("void") }
          return "sent" if candidates.any? { |value| value.include?("sent") }
          return "created" if candidates.any? { |value| value.include?("create") }

          nil
        end

        def update_envelope(envelope, envelope_status, now)
          attrs = { status: envelope_status, last_synced_at: now }
          attrs[:sent_at] = now if envelope_status == "sent" && envelope.sent_at.blank?
          attrs[:completed_at] = now if envelope_status == "completed" && envelope.completed_at.blank?
          attrs[:declined_at] = now if envelope_status == "declined" && envelope.declined_at.blank?
          attrs[:voided_at] = now if envelope_status == "voided" && envelope.voided_at.blank?
          envelope.update!(attrs)
        end

        def update_contract(contract, envelope_status, now)
          contract_status = {
            "created" => "prepared",
            "sent" => "sent",
            "delivered" => "delivered",
            "completed" => "signed",
            "declined" => "declined",
            "voided" => "voided"
          }[envelope_status]
          return if contract_status.blank?

          attrs = { status: contract_status }
          attrs[:sent_at] = now if contract_status == "sent" && contract.sent_at.blank?
          attrs[:completed_at] = now if contract_status == "signed" && contract.completed_at.blank?
          contract.update!(attrs)
        end
    end
  end
end
