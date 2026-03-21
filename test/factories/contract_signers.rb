FactoryBot.define do
  factory :contract_signer do
    association :contract
    sequence(:name) { |n| "Signer #{n}" }
    sequence(:email) { |n| "signer_#{n}@example.com" }
    role_name { "signer" }
    sequence(:routing_order) { |n| n }
    signing_type { "signer" }
    status { "pending" }
    metadata { {} }

    trait :signer do
      signing_type { "signer" }
    end

    trait :carbon_copy do
      signing_type { "carbon_copy" }
      role_name { "cc" }
    end
  end
end
