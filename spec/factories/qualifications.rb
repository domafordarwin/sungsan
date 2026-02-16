FactoryBot.define do
  factory :qualification do
    parish
    sequence(:name) { |n| "자격#{n}" }
    validity_months { 12 }
  end
end
