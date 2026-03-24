module Integrations
  module Feishu
    class EventsController < ActionController::API
      include AuditLoggable

      def create
        payload = params.to_unsafe_h
        raw_body = request.raw_post.to_s

        if payload["challenge"].present?
          return render_challenge(payload)
        end

        unless request_verified?(payload: payload, raw_body: raw_body)
          Rails.logger.warn("[Feishu::Events] verification failed request_id=#{request.request_id}")
          return render json: { error: "invalid feishu webhook signature" }, status: :unauthorized
        end

        Rails.logger.info("[Feishu::Events] event received request_id=#{request.request_id} type=#{event_type(payload)}")
        audit(action: "feishu_event_received", data: payload)
        head :ok
      end

      private

        def render_challenge(payload)
          unless challenge_token_valid?(payload)
            return render json: { error: "invalid feishu challenge token" }, status: :unauthorized
          end

          render json: { challenge: payload["challenge"] }
        end

        def request_verified?(payload:, raw_body:)
          signature_result = signature_verified?(raw_body: raw_body)
          return signature_result unless signature_result.nil?

          token_verified?(payload)
        end

        def signature_verified?(raw_body:)
          timestamp = request.headers["X-Lark-Request-Timestamp"].to_s
          nonce = request.headers["X-Lark-Request-Nonce"].to_s
          signature = request.headers["X-Lark-Signature"].to_s
          return nil if [timestamp, nonce, signature].any?(&:blank?)

          ::Feishu::EventSignatureVerifier.new.valid?(
            timestamp: timestamp,
            nonce: nonce,
            signature: signature,
            body: raw_body
          )
        end

        def token_verified?(payload)
          expected_token = ENV.fetch("feishu_app_verification_token", nil).to_s
          return true if expected_token.blank?

          received_token = payload["token"].presence || payload.dig("header", "token").presence
          received_token.present? && ActiveSupport::SecurityUtils.secure_compare(received_token, expected_token)
        end

        def challenge_token_valid?(payload)
          expected_token = ENV.fetch("feishu_app_verification_token", nil).to_s
          return true if expected_token.blank?

          token = payload["token"].to_s
          token.present? && ActiveSupport::SecurityUtils.secure_compare(token, expected_token)
        end

        def event_type(payload)
          payload.dig("event", "type") || payload.dig("header", "event_type") || payload["type"] || "unknown"
        end
    end
  end
end
