module Tenant
  module IntegrationGuides
    class SapsController < BaseController
      def show
        render "tenant/integration_guides/sap"
      end
    end
  end
end
