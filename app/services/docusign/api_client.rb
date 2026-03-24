module Docusign
  class ApiClient
    RETRYABLE_STATUS_CODES = [429, 500, 502, 503, 504].freeze

    class << self
      def post(connection:, path:, body:)
        request(connection:, method: :post, path:, body:)
      end

      def get(connection:, path:)
        request(connection:, method: :get, path:)
      end

      private

        def request(connection:, method:, path:, body: nil)
          raise Docusign::ConfigurationError, "missing docusign_base_uri" if connection.docusign_base_uri.blank?
          raise Docusign::ConfigurationError, "missing docusign_account_id" if connection.docusign_account_id.blank?

          access_token = Docusign::TokenManager.current_access_token(connection)
          url = "#{connection.docusign_base_uri}/v2.1/accounts/#{connection.docusign_account_id}#{path}"
          max_attempts = request_retry_count + 1
          attempt = 0

          while attempt < max_attempts
            attempt += 1
            begin
              response = Faraday.send(method, url) do |req|
                req.headers["Authorization"] = "Bearer #{access_token}"
                req.headers["Content-Type"] = "application/json"
                req.options.timeout = request_timeout_seconds
                req.options.open_timeout = request_open_timeout_seconds
                req.body = body.to_json if body
              end

              parsed = parse_response_body(response.body)

              if response.status.between?(200, 299)
                return parsed
              end

              if retryable_status?(response.status) && attempt < max_attempts
                wait_before_retry(attempt)
                next
              end

              raise Docusign::ApiError, "docusign api failed: status=#{response.status} body=#{parsed}"
            rescue Faraday::TimeoutError, Faraday::ConnectionFailed, Faraday::SSLError => e
              if attempt < max_attempts
                wait_before_retry(attempt)
                next
              end

              raise Docusign::ApiError, "docusign api request failed: #{e.class}: #{e.message}"
            end
          end
        rescue JSON::ParserError
          raise Docusign::ApiError, "docusign api returned invalid json"
        end

        def parse_response_body(body)
          JSON.parse(body.presence || "{}")
        end

        def retryable_status?(status_code)
          RETRYABLE_STATUS_CODES.include?(status_code.to_i)
        end

        def wait_before_retry(attempt)
          Kernel.sleep(request_retry_interval_seconds * (2**(attempt - 1)))
        end

        def request_timeout_seconds
          integer_with_default(ENV["docusign_api_timeout_seconds"], 25)
        end

        def request_open_timeout_seconds
          integer_with_default(ENV["docusign_api_open_timeout_seconds"], 8)
        end

        def request_retry_count
          integer_with_default(ENV["docusign_api_retry_count"], 2)
        end

        def request_retry_interval_seconds
          float_with_default(ENV["docusign_api_retry_interval_seconds"], 0.4)
        end

        def integer_with_default(value, default)
          Integer(value)
        rescue ArgumentError, TypeError
          default
        end

        def float_with_default(value, default)
          Float(value)
        rescue ArgumentError, TypeError
          default
        end
    end
  end
end
