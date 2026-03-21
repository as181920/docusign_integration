module Docusign
  class WebhookPayloadParser
    class << self
      def call(payload_text)
        JSON.parse(payload_text)
      rescue JSON::ParserError
        {}
      end
    end
  end
end
