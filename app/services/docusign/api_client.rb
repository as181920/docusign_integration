module Docusign
  class ApiClient
    class << self
      def post!(connection:, path:, body:)
        request!(connection:, method: :post, path:, body:)
      end

      def get!(connection:, path:)
        request!(connection:, method: :get, path:)
      end

      private

        def request!(connection:, method:, path:, body: nil)
          raise Docusign::ConfigurationError, "missing docusign_base_uri" if connection.docusign_base_uri.blank?
          raise Docusign::ConfigurationError, "missing docusign_account_id" if connection.docusign_account_id.blank?

          access_token = Docusign::TokenManager.current_access_token!(connection)
          url = "#{connection.docusign_base_uri}/v2.1/accounts/#{connection.docusign_account_id}#{path}"

          response = Faraday.send(method, url) do |req|
            req.headers["Authorization"] = "Bearer #{access_token}"
            req.headers["Content-Type"] = "application/json"
            req.body = body.to_json if body
          end

          parsed = JSON.parse(response.body.presence || "{}")
          raise Docusign::ApiError, "docusign api failed: status=#{response.status} body=#{parsed}" unless response.status.between?(200, 299)

          parsed
        rescue JSON::ParserError
          raise Docusign::ApiError, "docusign api returned invalid json"
        end
    end
  end
end
