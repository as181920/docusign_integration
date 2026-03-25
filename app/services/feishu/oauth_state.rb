module Feishu
  class OauthState
    PURPOSE = "feishu_oauth_state".freeze

    class << self
      def generate(tenant_uid: nil, tenant_user_id: nil, return_to: nil)
        payload = {
          tenant_user_id: tenant_user_id,
          issued_at: Time.current.to_i
        }
        payload[:tenant_uid] = tenant_uid if tenant_uid.present?
        payload[:return_to] = return_to if return_to.present?

        verifier.generate(payload, expires_in: 15.minutes, purpose: PURPOSE)
      end

      def verify(state)
        verifier.verify(state, purpose: PURPOSE).with_indifferent_access
      rescue StandardError => e
        raise Feishu::OauthStateError, "invalid feishu oauth state: #{e.message}"
      end

      private

        def verifier
          @verifier ||= ActiveSupport::MessageVerifier.new(Rails.application.secret_key_base, serializer: JSON)
        end
    end
  end
end
