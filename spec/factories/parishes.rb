FactoryBot.define do
  factory :parish do
    sequence(:name) { |n| "테스트본당#{n}" }
    address { "서울시 마포구" }
    phone { "02-123-4567" }
  end
end
