require "test_helper"

module Docusign
  class ApiClientTest < ActiveSupport::TestCase
    def create_connection
      tenant = create(:tenant, :acme)
      tenant_user = create(:tenant_user, :alice, tenant: tenant)
      create(:tenant_docusign_connection, :acme_connection, tenant: tenant, connected_by_tenant_user: tenant_user)
    end

    test "post sends bearer token and json body" do
      connection = create_connection
      response = Struct.new(:status, :body).new(201, '{"envelopeId":"env-1","status":"sent"}')
      captured = {}
      req = Struct.new(:headers, :body).new({}, nil)

      TokenManager.stubs(:current_access_token!).returns("access-123")
      Faraday.expects(:post).with { |url| captured[:url] = url; true }.yields(req).returns(response)

      body = ApiClient.post!(connection: connection, path: "/envelopes", body: { status: "sent" })

      assert_equal "env-1", body["envelopeId"]

      captured[:headers] = req.headers
      captured[:body] = req.body

      assert_match "/accounts/acct_acme/envelopes", captured[:url]
      assert_equal "Bearer access-123", captured[:headers]["Authorization"]
      assert_equal "application/json", captured[:headers]["Content-Type"]
      assert_equal({ status: "sent" }.to_json, captured[:body])
    end

    test "get parses json body" do
      connection = create_connection
      response = Struct.new(:status, :body).new(200, '{"ok":true}')
      req = Struct.new(:headers, :body).new({}, nil)

      TokenManager.stubs(:current_access_token!).returns("access")
      Faraday.expects(:get).yields(req).returns(response)

      assert ApiClient.get!(connection: connection, path: "/ping")["ok"]
    end

    test "raises configuration error when base uri missing" do
      connection = create_connection
      connection.update!(docusign_base_uri: nil)

      assert_raises(Docusign::ConfigurationError) { ApiClient.get!(connection: connection, path: "/ping") }
    end

    test "raises api error for non success responses" do
      connection = create_connection
      response = Struct.new(:status, :body).new(400, '{"error":"invalid"}')
      req = Struct.new(:headers, :body).new({}, nil)

      TokenManager.stubs(:current_access_token!).returns("access")
      Faraday.expects(:get).yields(req).returns(response)

      assert_raises(Docusign::ApiError) { ApiClient.get!(connection: connection, path: "/ping") }
    end

    test "raises api error for invalid json responses" do
      connection = create_connection
      response = Struct.new(:status, :body).new(200, "not-json")
      req = Struct.new(:headers, :body).new({}, nil)

      TokenManager.stubs(:current_access_token!).returns("access")
      Faraday.expects(:get).yields(req).returns(response)

      assert_raises(Docusign::ApiError) { ApiClient.get!(connection: connection, path: "/ping") }
    end
  end
end
