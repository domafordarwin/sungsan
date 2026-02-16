FactoryBot.define do
  factory :audit_log do
    action { "create" }
    association :auditable, factory: :member
    changes_data { { "name" => "테스트" } }
  end
end
