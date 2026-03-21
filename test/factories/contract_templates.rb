FactoryBot.define do
  factory :contract_template do
    association :tenant
    name { "Master Service Agreement" }
    sequence(:version) { |n| n }
    status { "active" }
    sequence(:docusign_template_id) { |n| "tpl_#{n}" }
    description { "Standard template" }
    metadata { {} }

    trait :acme_v1 do
      name { "Master Service Agreement" }
      version { 1 }
      docusign_template_id { "tpl_acme_v1" }
      description { "Standard MSA template" }
    end

    trait :acme_v2 do
      name { "Master Service Agreement" }
      version { 2 }
      docusign_template_id { "tpl_acme_v2" }
      description { "Standard MSA template v2" }
    end
  end
end
