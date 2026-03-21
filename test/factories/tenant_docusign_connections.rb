FactoryBot.define do
  factory :tenant_docusign_connection do
    association :tenant
    connected_by_tenant_user { association :tenant_user, tenant: tenant }
    sequence(:docusign_account_id) { |n| "acct_#{n}" }
    docusign_base_uri { "https://demo.docusign.net/restapi" }
    oauth_scope { "signature" }
    sequence(:access_token) { |n| "access_token_#{n}" }
    sequence(:refresh_token) { |n| "refresh_token_#{n}" }
    token_expires_at { 1.hour.from_now }
    connected_at { 1.day.ago }
    status { "active" }
    metadata { {} }

    trait :acme_connection do
      docusign_account_id { "acct_acme" }
      access_token { "access_token_acme" }
      refresh_token { "refresh_token_acme" }
    end

    trait :beta_connection do
      docusign_account_id { "acct_beta" }
      access_token { "access_token_beta" }
      refresh_token { "refresh_token_beta" }
    end
  end
end
