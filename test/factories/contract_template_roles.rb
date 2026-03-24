FactoryBot.define do
  factory :contract_template_role do
    association :contract_template
    sequence(:role_name) { |n| "Signer #{n}" }
    signer_name { nil }
    signer_email { nil }
    sequence(:routing_order) { |n| n }
    signing_type { "signer" }
    metadata { {} }
  end
end
