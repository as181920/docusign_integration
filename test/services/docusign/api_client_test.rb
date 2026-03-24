require "test_helper"

module Docusign
  class ApiClientTest < ActiveSupport::TestCase
    RequestOptions = Struct.new(:timeout, :open_timeout)

    def create_connection
      tenant = create(:tenant, :acme)
      tenant_user = create(:tenant_user, :alice, tenant: tenant)
      create(:tenant_docusign_connection, :acme_connection, tenant: tenant, connected_by_tenant_user: tenant_user)
    end

    def build_request
      Struct.new(:headers, :body, :options).new({}, nil, RequestOptions.new)
    end

    test "post sends bearer token and json body" do
      connection = create_connection
      response = Struct.new(:status, :body).new(201, '{"envelopeId":"env-1","status":"sent"}')
      captured = {}
      req = build_request

      TokenManager.stubs(:current_access_token).returns("access-123")
      Faraday.expects(:post).with { |url| captured[:url] = url; true }.yields(req).returns(response)

      body = ApiClient.post(connection: connection, path: "/envelopes", body: { status: "sent" })

      captured[:headers] = req.headers
      captured[:body] = req.body

      assert_match "/accounts/acct_acme/envelopes", captured[:url]
      assert_equal "Bearer access-123", captured[:headers]["Authorization"]
      assert_equal "application/json", captured[:headers]["Content-Type"]
      assert_equal({ status: "sent" }.to_json, captured[:body])
      assert_equal "env-1", body["envelopeId"]
    end

    test "get parses json body" do
      connection = create_connection
      response = Struct.new(:status, :body).new(200, '{"ok":true}')
      req = build_request

      TokenManager.stubs(:current_access_token).returns("access")
      Faraday.expects(:get).yields(req).returns(response)

      assert ApiClient.get(connection: connection, path: "/ping")["ok"]
    end

    test "post sets request timeout options" do
      connection = create_connection
      response = Struct.new(:status, :body).new(200, '{"ok":true}')
      req = build_request

      TokenManager.stubs(:current_access_token).returns("access")
      Faraday.expects(:post).yields(req).returns(response)
      ApiClient.post(connection: connection, path: "/envelopes", body: { status: "sent" })

      assert_equal 25, req.options.timeout
      assert_equal 8, req.options.open_timeout
    end

    test "raises configuration error when base uri missing" do
      connection = create_connection
      connection.update!(docusign_base_uri: nil)

      assert_raises(Docusign::ConfigurationError) { ApiClient.get(connection: connection, path: "/ping") }
    end

    test "raises api error for non success responses" do
      connection = create_connection
      response = Struct.new(:status, :body).new(400, '{"error":"invalid"}')
      req = build_request

      TokenManager.stubs(:current_access_token).returns("access")
      Faraday.expects(:get).yields(req).returns(response)

      assert_raises(Docusign::ApiError) { ApiClient.get(connection: connection, path: "/ping") }
    end

    test "raises api error for invalid json responses" do
      connection = create_connection
      response = Struct.new(:status, :body).new(200, "not-json")
      req = build_request

      TokenManager.stubs(:current_access_token).returns("access")
      Faraday.expects(:get).yields(req).returns(response)

      assert_raises(Docusign::ApiError) { ApiClient.get(connection: connection, path: "/ping") }
    end

    test "retries timeout errors and succeeds" do
      connection = create_connection
      first_req = build_request
      second_req = build_request
      retry_sequence = sequence("timeout retry")

      TokenManager.stubs(:current_access_token).returns("access")
      ApiClient.expects(:wait_before_retry).once
      Faraday.expects(:get).in_sequence(retry_sequence).yields(first_req).raises(Faraday::TimeoutError.new("timeout"))
      Faraday.expects(:get).in_sequence(retry_sequence).yields(second_req).returns(Struct.new(:status, :body).new(200, '{"ok":true}'))

      body = ApiClient.get(connection: connection, path: "/ping")

      assert(body["ok"])
    end

    test "retries retryable status and succeeds" do
      connection = create_connection
      first_req = build_request
      second_req = build_request
      retry_sequence = sequence("status retry")

      TokenManager.stubs(:current_access_token).returns("access")
      ApiClient.expects(:wait_before_retry).once
      Faraday.expects(:get).in_sequence(retry_sequence).yields(first_req).returns(Struct.new(:status, :body).new(503, '{"error":"temporarily_unavailable"}'))
      Faraday.expects(:get).in_sequence(retry_sequence).yields(second_req).returns(Struct.new(:status, :body).new(200, '{"ok":true}'))

      body = ApiClient.get(connection: connection, path: "/ping")

      assert(body["ok"])
    end
  end
end
