require "uri"

module Feishu
  class OauthClient
    def initialize(
      oauth_base_uri: ENV.fetch("feishu_oauth_base_uri", "https://open.feishu.cn"),
      app_id: ENV.fetch("feishu_app_id", nil),
      app_secret: ENV.fetch("feishu_app_secret", nil),
      redirect_uri: ENV.fetch("feishu_oauth_redirect_uri", nil)
    )
      @oauth_base_uri = oauth_base_uri.to_s.sub(%r{/$}, "")
      @app_id = app_id
      @app_secret = app_secret
      @redirect_uri = redirect_uri.presence || default_redirect_uri

      raise Feishu::ConfigurationError, "missing feishu oauth config" if [@oauth_base_uri, @app_id, @app_secret, @redirect_uri].any?(&:blank?)
    end

    def authorization_url(state:)
      query = {
        app_id: @app_id,
        redirect_uri: @redirect_uri,
        state: state
      }

      "#{@oauth_base_uri}/open-apis/authen/v1/index?#{URI.encode_www_form(query)}"
    end

    def exchange_code(code:)
      response = Faraday.post("#{@oauth_base_uri}/open-apis/authen/v2/oauth/token") do |req|
        req.headers["Content-Type"] = "application/json"
        req.body = {
          grant_type: "authorization_code",
          code: code,
          client_id: @app_id,
          client_secret: @app_secret,
          redirect_uri: @redirect_uri
        }.to_json
      end

      body = parse_json(response)
      ensure_success(response, body)
      unwrap_data(body)
    end

    def user_info(access_token:)
      response = Faraday.get("#{@oauth_base_uri}/open-apis/authen/v1/user_info") do |req|
        req.headers["Authorization"] = "Bearer #{access_token}"
      end

      body = parse_json(response)
      ensure_success(response, body)
      unwrap_data(body)
    end

    private

      def default_redirect_uri
        configured_backend_base = ENV.fetch("app_backend_base_url", nil).to_s.sub(%r{/$}, "")
        return nil if configured_backend_base.blank?

        "#{configured_backend_base}/integrations/feishu/callback"
      end

      def parse_json(response)
        JSON.parse(response.body)
      rescue JSON::ParserError
        { "raw_body" => response.body }
      end

      def ensure_success(response, body)
        return if response.status.between?(200, 299) && api_success?(body)

        raise Feishu::ApiError, "feishu oauth failed: status=#{response.status} body=#{body}"
      end

      def api_success?(body)
        code = body["code"]
        return true if code.blank?

        code.to_i.zero?
      end

      def unwrap_data(body)
        data = body["data"]
        return data if data.is_a?(Hash)

        body
      end
  end
end
