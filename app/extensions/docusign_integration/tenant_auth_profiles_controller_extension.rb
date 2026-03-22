require TenantAuth::Engine.root.join("app/controllers/tenant_auth/profiles_controller")

module DocusignIntegration
  module TenantAuthProfilesControllerExtension
    extend ActiveSupport::Concern

    included do
      layout -> { request.format.html? ? "tenant/admin" : false }
    end
  end
end

unless TenantAuth::ProfilesController < DocusignIntegration::TenantAuthProfilesControllerExtension
  TenantAuth::ProfilesController.include DocusignIntegration::TenantAuthProfilesControllerExtension
end
