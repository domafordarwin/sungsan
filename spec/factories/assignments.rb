FactoryBot.define do
  factory :assignment do
    event
    role
    member
    status { "pending" }

    trait :pending do
      status { "pending" }
    end

    trait :accepted do
      status { "accepted" }
      responded_at { Time.current }
    end

    trait :declined do
      status { "declined" }
      responded_at { Time.current }
      decline_reason { "개인 사정" }
    end
  end
end
