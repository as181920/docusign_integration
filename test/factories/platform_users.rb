FactoryBot.define do
  factory :platform_user, class: "UserAuth::User" do
    sequence(:uid) { |n| "usr_#{n}" }
    sequence(:name) { |n| "platform_user_#{n}" }
    password { "password" }
  end
end
