module Tenant
  class BaseController < ApplicationController
    include Tenant::AuthGuard

    layout "tenant/admin"
  end
end
