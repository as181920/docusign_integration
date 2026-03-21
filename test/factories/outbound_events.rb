FactoryBot.define do
  factory :outbound_event do
    association :tenant
    event_name { "contract.signed" }
    payload { {} }
    status { "pending" }
    attempts { 0 }
  end
end
