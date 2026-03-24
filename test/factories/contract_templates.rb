FactoryBot.define do
  factory :contract_template do
    association :tenant
    sequence(:name) { |n| "Contract Template #{n}" }
    sequence(:version) { |n| n }
    status { "active" }
    sequence(:docusign_template_id) { |n| "tpl_#{n}" }
    description { "Standard template" }
    email_subject { "Please sign this document" }
    email_message { "Please review and sign." }
    publish_state { "published" }
    published_at { Time.current }
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
