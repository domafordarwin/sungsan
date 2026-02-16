FactoryBot.define do
  factory :user do
    parish
    sequence(:email_address) { |n| "user#{n}@example.com" }
    password { "password123" }
    name { Faker::Name.name }
    role { "member" }

    trait :admin do
      role { "admin" }
    end

    trait :operator do
      role { "operator" }
    end

    trait :member_role do
      role { "member" }
    end
  end
end
