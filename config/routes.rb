Rails.application.routes.draw do
  get "up", to: "rails/health#show", as: :rails_health_check

  mount MissionControl::Jobs::Engine, at: "/jobs"

  mount WechatOpenPlatformProxy::Engine, at: "/owx"
  mount WechatVendorPlatformProxy::Engine, at: "/wxpay"
  mount WechatWorkPlatformProxy::Engine, at: "/wecom"

  mount OmniRegion::Engine, at: "/omni_region"

  mount EasyStyle::Engine, at: "/easy_style"

  mount AnonymousAuthorization::Engine, at: "/anonymous_auth"
  mount UserAuth::Engine, at: "/user_auth"
  mount OrganizationAuth::Engine, at: "/organization_auth"
  mount TenantAuth::Engine, at: "/tenant_auth"

  namespace :integrations do
    namespace :feishu do
      get "callback", to: "callbacks#show"
      post "events", to: "events#create"
    end

    namespace :docusign do
      get "oauth/callback", to: "oauth_callbacks#show"
    end
  end

  scope "/t/:tenant_uid", module: :tenant_scoped, as: :tenant_scoped do
    get "dashboard", to: "dashboards#show"

    resources :contract_templates, only: %i[index show create update]

    resources :contracts, only: %i[index show create] do
      resources :signers, only: %i[index create], controller: "contract_signers"

      member do
        post :send_to_docusign
        post :embedded_signing_url
      end
    end

    resource :docusign_connection, only: %i[show create update], controller: "docusign_connections" do
      get :authorize_url
    end
  end

  namespace :webhooks do
    post "docusign", to: "docusign#create"
  end

  root to: "rails/health#show"
end
