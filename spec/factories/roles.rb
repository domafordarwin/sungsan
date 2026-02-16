FactoryBot.define do
  factory :role do
    parish
    sequence(:name) { |n| "역할#{n}" }
    sort_order { 0 }
    active { true }

    trait :requires_baptism do
      requires_baptism { true }
    end

    trait :requires_confirmation do
      requires_confirmation { true }
    end
  end
end
