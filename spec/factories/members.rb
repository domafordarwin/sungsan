FactoryBot.define do
  factory :member do
    parish
    name { Faker::Name.name }
    phone { "010-#{rand(1000..9999)}-#{rand(1000..9999)}" }
    baptismal_name { "베드로" }
    baptized { true }
    confirmed { false }
    active { true }
    district { "#{rand(1..10)}구역" }

    trait :active do
      active { true }
    end

    trait :inactive do
      active { false }
    end

    trait :baptized do
      baptized { true }
    end

    trait :confirmed do
      confirmed { true }
    end

    trait :with_user do
      user
    end
  end
end
