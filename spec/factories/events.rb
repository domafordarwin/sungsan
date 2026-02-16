FactoryBot.define do
  factory :event do
    parish
    event_type
    date { Date.current + 7.days }
    start_time { "09:00" }

    trait :upcoming do
      date { Date.current + 7.days }
    end

    trait :past do
      date { Date.current - 7.days }
    end
  end
end
