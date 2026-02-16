FactoryBot.define do
  factory :attendance_record do
    event
    member
    status { "present" }

    trait :present do
      status { "present" }
    end

    trait :late do
      status { "late" }
    end

    trait :absent do
      status { "absent" }
    end
  end
end
