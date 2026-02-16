FactoryBot.define do
  factory :member_qualification do
    member
    qualification
    acquired_date { Date.current }
    expires_date { Date.current + 12.months }
  end
end
