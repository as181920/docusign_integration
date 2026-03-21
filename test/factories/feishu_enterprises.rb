FactoryBot.define do
  factory :feishu_enterprise do
    association :tenant
    sequence(:tenant_key) { |n| "fs_tenant_key_#{n}" }
    app_id { "cli_test_app" }
    sequence(:name) { |n| "Feishu Enterprise #{n}" }
    status { "active" }
    raw_payload { {} }

    trait :acme_enterprise do
      tenant_key { "fs_acme_key" }
      name { "ACME Feishu Enterprise" }
    end
  end
end
