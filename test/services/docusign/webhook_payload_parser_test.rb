require "test_helper"

module Docusign
  class WebhookPayloadParserTest < ActiveSupport::TestCase
    test "parses valid json" do
      payload = described_class.call('{"event":"envelope-completed"}')

      assert_equal "envelope-completed", payload["event"]
    end

    test "returns empty hash for invalid json" do
      assert_equal({}, described_class.call("not-json"))
    end

    private

      def described_class
        Docusign::WebhookPayloadParser
      end
  end
end
