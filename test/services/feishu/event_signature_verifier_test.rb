require "test_helper"
require "openssl"

module Feishu
  class EventSignatureVerifierTest < ActiveSupport::TestCase
    test "valid returns true when signature matches" do
      body = '{"event":{"type":"app_ticket"}}'
      timestamp = "1774329600"
      nonce = "nonce-1"
      encrypt_key = "encrypt-key"
      signature = OpenSSL::Digest::SHA256.hexdigest("#{timestamp}#{nonce}#{encrypt_key}#{body}")

      verifier = EventSignatureVerifier.new(encrypt_key: encrypt_key)

      assert verifier.valid?(timestamp: timestamp, nonce: nonce, signature: signature, body: body)
    end

    test "valid returns false when signature mismatches" do
      verifier = EventSignatureVerifier.new(encrypt_key: "encrypt-key")

      assert_not verifier.valid?(timestamp: "1", nonce: "2", signature: "bad", body: "{}")
    end
  end
end
