FactoryBot.define do
  factory :organization, class: "OrganizationAuth::Organization" do
    sequence(:uid) { |n| "org_#{n}" }
    sequence(:name) { |n| "Organization #{n}" }
    custom_settings { {} }
  end
end
