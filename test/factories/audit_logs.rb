FactoryBot.define do
  factory :audit_log do
    association :tenant
    actor_type { "TenantAuth::User" }
    actor_id { nil }
    action { "contract_created" }
    target_type { "Contract" }
    target_id { nil }
    request_id { "test-request-id" }
    ip { "127.0.0.1" }
    user_agent { "RailsTest" }
    data { {} }
  end
end
