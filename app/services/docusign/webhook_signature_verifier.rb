require "base64"
require "openssl"

module Docusign
  class WebhookSignatureVerifier
    class << self
      def valid?(payload:, signature:, secret:)
        return true if secret.blank?
        return false if signature.blank?

        expected_signature = Base64.strict_encode64(OpenSSL::HMAC.digest("SHA256", secret, payload))
        ActiveSupport::SecurityUtils.secure_compare(expected_signature, signature)
      rescue StandardError
        false
      end
    end
  end
end
