module Integrations
  module Feishu
    class EventsController < ActionController::API
      include AuditLoggable

      def create
        raw_body = request.raw_post.to_s
        payload = build_payload(raw_body: raw_body)
        challenge = extract_challenge(payload)

        if challenge.present?
          return render_challenge(payload: payload, challenge: challenge)
        end

        unless request_verified?(payload: payload, raw_body: raw_body)
          Rails.logger.warn("[Feishu::Events] verification failed request_id=#{request.request_id}")
          return render json: { error: "invalid feishu webhook signature" }, status: :unauthorized
        end

        Rails.logger.info("[Feishu::Events] event received request_id=#{request.request_id} type=#{event_type(payload)}")
        audit(action: "feishu_event_received", data: payload)
        render json: { code: 0 }
      end

      private

        def build_payload(raw_body:)
          payload = params.to_unsafe_h.stringify_keys.except("controller", "action")
          payload = parse_json_body(raw_body) if payload.blank? && raw_body.present?
          payload = payload.stringify_keys

          decrypt_payload(payload).merge(payload)
        end

        def parse_json_body(raw_body)
          JSON.parse(raw_body)
        rescue JSON::ParserError
          {}
        end

        def decrypt_payload(payload)
          encrypted = payload["encrypt"].to_s
          return {} if encrypted.blank?

          decrypt_keys.each do |encrypt_key|
            begin
              return ::Feishu::EventPayloadDecryptor.new(encrypt_key: encrypt_key).decrypt(encrypted).stringify_keys
            rescue ::Feishu::Error
              next
            end
          end

          raise ::Feishu::Error, "failed to decrypt feishu payload with configured encrypt keys"
        rescue ::Feishu::Error => e
          Rails.logger.warn("[Feishu::Events] decrypt failed request_id=#{request.request_id} error=#{e.message}")
          {}
        end

        def extract_challenge(payload)
          payload["challenge"].presence || payload.dig("header", "challenge").presence
        end

        def render_challenge(payload:, challenge:)
          unless challenge_token_valid?(payload)
            return render json: { error: "invalid feishu challenge token" }, status: :unauthorized
          end

          render json: { challenge: challenge }
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

          return false if decrypt_keys.empty?

          decrypt_keys.any? do |encrypt_key|
            ::Feishu::EventSignatureVerifier.new(encrypt_key: encrypt_key).valid?(
              timestamp: timestamp,
              nonce: nonce,
              signature: signature,
              body: raw_body
            )
          end
        end

        def token_verified?(payload)
          return true if verification_tokens.empty?

          received_token = payload["token"].presence || payload.dig("header", "token").presence
          token_matched?(received_token)
        end

        def challenge_token_valid?(payload)
          return true if verification_tokens.empty?

          token = payload["token"].presence || payload.dig("header", "token").presence
          token_matched?(token)
        end

        def event_type(payload)
          payload.dig("event", "type") || payload.dig("header", "event_type") || payload["type"] || "unknown"
        end

        def token_matched?(token)
          return false if token.blank?

          verification_tokens.any? do |expected_token|
            next false if expected_token.bytesize != token.bytesize

            ActiveSupport::SecurityUtils.secure_compare(token.to_s, expected_token)
          end
        end

        def verification_tokens
          @verification_tokens ||= begin
            FeishuEnterprise.where.not(app_verification_token: [nil, ""]).pluck(:app_verification_token).uniq
          end
        end

        def decrypt_keys
          @decrypt_keys ||= begin
            FeishuEnterprise.where.not(app_encrypt_key: [nil, ""]).pluck(:app_encrypt_key).uniq
          end
        end
    end
  end
end
