FactoryBot.define do
  factory :availability_rule do
    member
    day_of_week { 0 }
    available { true }
  end
end
