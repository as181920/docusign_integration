require "openssl"

module Feishu
  class EventSignatureVerifier
    def initialize(encrypt_key: nil)
      @encrypt_key = encrypt_key.to_s
    end

    def valid?(timestamp:, nonce:, signature:, body:)
      return false if [timestamp, nonce, signature, body].any?(&:blank?)
      return false if @encrypt_key.blank?

      expected = OpenSSL::Digest::SHA256.hexdigest("#{timestamp}#{nonce}#{@encrypt_key}#{body}")
      secure_compare(expected, signature.to_s.downcase)
    end

    private

      def secure_compare(expected, actual)
        return false if expected.bytesize != actual.bytesize

        ActiveSupport::SecurityUtils.secure_compare(expected, actual)
      end
  end
end
