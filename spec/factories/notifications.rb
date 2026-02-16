FactoryBot.define do
  factory :notification do
    parish
    notification_type { "assignment" }
    channel { "email" }
    subject { "배정 알림" }
    body { "봉사 배정이 있습니다." }
    status { "pending" }
  end
end
