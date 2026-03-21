FactoryBot.define do
  factory :contract do
    association :tenant
    creator_tenant_user { association :tenant_user, tenant: tenant }
    sequence(:title) { |n| "Contract #{n}" }
    sequence(:contract_no) { |n| "C-#{n.to_s.rjust(6, "0")}" }
    status { "draft" }
    source { "manual" }
    language { "en" }
    currency { "USD" }
    metadata { {} }

    trait :acme_contract do
      title { "ACME Cross-Border Service Contract" }
      contract_no { "C-ACME-001" }
      docusign_template_id { "tpl_acme_v1" }
    end

    trait :acme_contract_without_template do
      title { "ACME Purchase Contract" }
      contract_no { "C-ACME-002" }
      docusign_template_id { nil }
    end

    trait :beta_contract do
      title { "Beta Contract" }
      contract_no { "C-BETA-001" }
      docusign_template_id { "tpl_beta_v1" }
    end
  end
end
