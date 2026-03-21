FactoryBot.define do
  factory :tenant_user, class: "TenantAuth::User" do
    association :tenant
    sequence(:name) { |n| "tenant_user_#{n}" }
    password { "password" }
    root { false }

    trait :alice do
      name { "alice" }
    end

    trait :bob do
      name { "bob" }
    end
  end
end
