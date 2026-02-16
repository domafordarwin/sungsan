FactoryBot.define do
  factory :blackout_period do
    member
    start_date { Date.current }
    end_date { Date.current + 7.days }
    reason { "휴가" }
  end
end
