require "base64"
require "openssl"

module Feishu
  class EventPayloadDecryptor
    def initialize(encrypt_key: ENV.fetch("feishu_app_encrypt_key", nil))
      @encrypt_key = encrypt_key.to_s
    end

    def decrypt(encrypted_payload)
      raise Feishu::Error, "feishu encrypt key missing" if @encrypt_key.blank?
      raise Feishu::Error, "encrypted payload is blank" if encrypted_payload.to_s.blank?

      encrypted_data = Base64.decode64(encrypted_payload)
      raise Feishu::Error, "invalid encrypted payload" if encrypted_data.bytesize <= 16

      iv = encrypted_data.byteslice(0, 16)
      cipher_text = encrypted_data.byteslice(16, encrypted_data.bytesize - 16)

      cipher = OpenSSL::Cipher.new("AES-256-CBC")
      cipher.decrypt
      cipher.key = OpenSSL::Digest::SHA256.digest(@encrypt_key)
      cipher.iv = iv

      plain_text = cipher.update(cipher_text) + cipher.final
      JSON.parse(plain_text)
    rescue ArgumentError, OpenSSL::Cipher::CipherError, JSON::ParserError => e
      raise Feishu::Error, "failed to decrypt feishu payload: #{e.message}"
    end
  end
end
