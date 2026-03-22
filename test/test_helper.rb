ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "mocha/minitest"

class ActiveSupport::TestCase
  include ActiveJob::TestHelper
  include ActiveSupport::Testing::TimeHelpers
  include FactoryBot::Syntax::Methods

  parallelize(workers: :number_of_processors)

  def json_body
    ::JSON.parse(response.body)
  end

  def with_env(overrides)
    original = {}
    overrides.each do |key, value|
      original[key] = ENV.key?(key) ? ENV[key] : :__missing__
      if value.nil?
        ENV.delete(key)
      else
        ENV[key] = value
      end
    end
    yield
  ensure
    original.each do |key, value|
      value == :__missing__ ? ENV.delete(key) : ENV[key] = value
    end
  end
end

class ActionDispatch::IntegrationTest
  def sign_in_tenant_user!(tenant_uid:, name:, password: "password")
    post "/tenant_auth/iam/sessions", params: {
      session: {
        tenant_uid: tenant_uid,
        name: name,
        password: password
      }
    }

    assert_response :redirect
  end
end
