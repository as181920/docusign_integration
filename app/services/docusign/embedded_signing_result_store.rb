require "securerandom"

module Docusign
  class EmbeddedSigningResultStore
    class << self
      def write(contract:, signer_email:, signing_url:)
        ref = SecureRandom.urlsafe_base64(18)
        payload = {
          tenant_id: contract.tenant_id,
          contract_id: contract.id,
          signer_email: signer_email,
          signing_url: signing_url
        }

        Rails.cache.write(cache_key(ref), payload, expires_in: cache_ttl_seconds)
        ref
      end

      def read_once(contract:, ref:)
        return nil if ref.blank?

        payload = Rails.cache.read(cache_key(ref))
        return nil if payload.blank?

        data = payload.with_indifferent_access
        return nil unless payload_matches_contract?(data:, contract:)

        Rails.cache.delete(cache_key(ref))
        {
          signer_email: data[:signer_email],
          signing_url: data[:signing_url]
        }
      end

      private

        def payload_matches_contract?(data:, contract:)
          data[:tenant_id].to_i == contract.tenant_id.to_i && data[:contract_id].to_i == contract.id.to_i
        end

        def cache_key(ref)
          "docusign:embedded_signing_result:#{ref}"
        end

        def cache_ttl_seconds
          Integer(ENV.fetch("docusign_embedded_signing_result_ttl_seconds", "600"))
        rescue ArgumentError, TypeError
          600
        end
    end
  end
end
