FactoryBot.define do
  factory :event_type do
    parish
    sequence(:name) { |n| "미사유형#{n}" }
    default_time { "09:00" }
    active { true }
  end
end
