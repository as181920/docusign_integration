require "test_helper"

module Docusign
  class WebhookSignatureVerifierTest < ActiveSupport::TestCase
    test "returns true when secret is blank" do
      assert described_class.valid?(payload: "x", signature: nil, secret: nil)
    end

    test "returns false when signature is blank and secret present" do
      assert_not described_class.valid?(payload: "x", signature: nil, secret: "secret")
    end

    test "validates hmac signature" do
      payload = '{"event":"ok"}'
      secret = "hmac-secret"
      signature = Base64.strict_encode64(OpenSSL::HMAC.digest("SHA256", secret, payload))

      assert described_class.valid?(payload: payload, signature: signature, secret: secret)
    end

    private

      def described_class
        Docusign::WebhookSignatureVerifier
      end
  end
end
