require TenantAuth::Engine.root.join("app/controllers/tenant_auth/application_controller")

module DocusignIntegration
  module TenantAuthApplicationControllerExtension
    extend ActiveSupport::Concern

    included do
      layout -> { request.format.html? ? "tenant/admin" : false }
    end
  end
end

unless TenantAuth::ApplicationController < DocusignIntegration::TenantAuthApplicationControllerExtension
  TenantAuth::ApplicationController.include DocusignIntegration::TenantAuthApplicationControllerExtension
end
