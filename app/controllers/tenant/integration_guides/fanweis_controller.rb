module Tenant
  module IntegrationGuides
    class FanweisController < BaseController
      def show
        render "tenant/integration_guides/fanwei"
      end
    end
  end
end
