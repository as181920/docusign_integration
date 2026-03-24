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
      resource :callback, only: :show, controller: "callbacks"
      resources :events, only: :create
    end

    namespace :docusign do
      resource :oauth_callback, only: :show, path: "oauth/callback", controller: "oauth_callbacks"
    end
  end

  scope "/t/:tenant_uid", module: :tenant, as: :tenant do
    resource :dashboard, only: :show, controller: "dashboards"

    resources :contract_templates, only: %i[index new show edit create update]
    resource :docusign_template_sync, only: :create
    resources :webhook_events, only: %i[index show]
    resources :sent_documents, only: :index

    resources :contracts, only: %i[index new show create] do
      resources :signers, only: %i[index create], controller: "contract_signers"

      scope module: :contracts do
        resource :docusign_envelope_submission, only: :create
        resource :embedded_signing_session, only: :create
      end
    end

    resource :docusign_connection, only: %i[show new edit create update], controller: "docusign_connections" do
      scope module: :docusign_connections do
        resource :oauth_authorization, only: :create
      end
    end

    namespace :integration_guides do
      resource :feishu, only: :show, controller: "feishus"
      resource :sap, only: :show, controller: "saps"
      resource :fanwei, only: :show, controller: "fanweis"
    end
  end

  namespace :webhooks do
    resource :docusign, only: :create, controller: "docusign"
  end

  root to: "welcome#show"
end
