FactoryBot.define do
  factory :event_role_requirement do
    event_type
    role
    required_count { 1 }
  end
end
