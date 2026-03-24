require "test_helper"

module Feishu
  class EventPayloadDecryptorTest < ActiveSupport::TestCase
    test "decrypt returns parsed json payload" do
      encrypt_key = "encrypt-key"
      payload = { "challenge" => "abc123", "token" => "verify-token" }.to_json
      iv = "0123456789abcdef"

      cipher = OpenSSL::Cipher.new("AES-256-CBC")
      cipher.encrypt
      cipher.key = OpenSSL::Digest::SHA256.digest(encrypt_key)
      cipher.iv = iv

      encrypted = Base64.strict_encode64(iv + cipher.update(payload) + cipher.final)

      decrypted = EventPayloadDecryptor.new(encrypt_key: encrypt_key).decrypt(encrypted)

      assert_equal "abc123", decrypted["challenge"]
      assert_equal "verify-token", decrypted["token"]
    end

    test "decrypt raises feishu error when payload invalid" do
      decryptor = EventPayloadDecryptor.new(encrypt_key: "encrypt-key")

      assert_raises(Feishu::Error) { decryptor.decrypt("invalid") }
    end
  end
end
