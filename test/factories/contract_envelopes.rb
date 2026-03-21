FactoryBot.define do
  factory :contract_envelope do
    association :contract
    tenant_docusign_connection do
      connection_user = contract.creator_tenant_user || association(:tenant_user, tenant: contract.tenant)
      association :tenant_docusign_connection, tenant: contract.tenant, connected_by_tenant_user: connection_user
    end
    sequence(:envelope_id) { |n| "env_#{n}" }
    status { "sent" }
    sent_at { 2.hours.ago }
    metadata { {} }

    trait :acme_envelope do
      envelope_id { "env_acme_001" }
    end
  end
end
