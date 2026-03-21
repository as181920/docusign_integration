FactoryBot.define do
  factory :external_identity do
    user { association :platform_user }
    tenant
    tenant_user { association(:tenant_user, tenant: tenant) }
    provider { "feishu" }
    sequence(:provider_uid) { |n| "union_#{n}" }
    union_id { provider_uid }
    sequence(:open_id) { |n| "open_#{n}" }
    sequence(:name) { |n| "Feishu User #{n}" }
    avatar_url { "https://example.com/avatar.png" }
    metadata { {} }
  end
end
