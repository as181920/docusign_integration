FactoryBot.define do
  factory :tenant, class: "TenantAuth::Tenant" do
    association :organization
    sequence(:uid) { |n| "tenant_#{n}" }
    sequence(:name) { |n| "Tenant #{n}" }
    state { 0 }
    custom_settings { {} }

    trait :acme do
      uid { "acme" }
      name { "ACME Tenant" }
    end

    trait :beta do
      uid { "beta" }
      name { "Beta Tenant" }
    end
  end
end
