FactoryBot.define do
  factory :webhook_event do
    association :tenant
    provider { "docusign" }
    sequence(:delivery_id) { |n| "delivery-#{n}" }
    event_type { "envelope-completed" }
    external_account_id { "acct_acme" }
    sequence(:external_event_id) { |n| "env_#{n}" }
    status { "received" }
    processing_attempts { 0 }
    received_at { 5.minutes.ago }
    headers { {} }
    payload { {} }
  end
end
