require "base64"
require "uri"

module Docusign
  class OauthClient
    def initialize(
      oauth_base_uri: ENV.fetch("docusign_oauth_base_uri", nil),
      integration_key: ENV.fetch("docusign_integration_key", nil),
      client_secret: ENV.fetch("docusign_client_secret", nil),
      redirect_uri: ENV.fetch("docusign_oauth_redirect_uri", nil)
    )
      @oauth_base_uri = oauth_base_uri.to_s.sub(%r{/$}, "")
      @integration_key = integration_key
      @client_secret = client_secret
      @redirect_uri = redirect_uri

      raise Docusign::ConfigurationError, "missing docusign oauth config" if [@oauth_base_uri, @integration_key, @client_secret, @redirect_uri].any?(&:blank?)
    end

    def authorization_url(state:, scope: "signature")
      query = {
        response_type: "code",
        scope: scope,
        client_id: @integration_key,
        redirect_uri: @redirect_uri,
        state: state
      }

      "#{@oauth_base_uri}/oauth/auth?#{URI.encode_www_form(query)}"
    end

    def exchange_code!(code:)
      request_token!(grant_type: "authorization_code", code: code, redirect_uri: @redirect_uri)
    end

    def refresh_token!(refresh_token:)
      request_token!(grant_type: "refresh_token", refresh_token: refresh_token)
    end

    def user_info!(access_token:)
      response = Faraday.get("#{@oauth_base_uri}/oauth/userinfo") do |req|
        req.headers["Authorization"] = "Bearer #{access_token}"
      end

      body = parse_json(response)
      ensure_success!(response, body)
      body
    end

    private

      def request_token!(params)
        response = Faraday.post("#{@oauth_base_uri}/oauth/token") do |req|
          req.headers["Authorization"] = "Basic #{basic_auth_token}"
          req.headers["Content-Type"] = "application/x-www-form-urlencoded"
          req.body = URI.encode_www_form(params)
        end

        body = parse_json(response)
        ensure_success!(response, body)
        body
      end

      def basic_auth_token
        Base64.strict_encode64("#{@integration_key}:#{@client_secret}")
      end

      def parse_json(response)
        JSON.parse(response.body)
      rescue JSON::ParserError
        { "raw_body" => response.body }
      end

      def ensure_success!(response, body)
        return if response.status.between?(200, 299)

        raise Docusign::ApiError, "docusign oauth failed: status=#{response.status} body=#{body}"
      end
  end
end
