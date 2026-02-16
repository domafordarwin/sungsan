class AvailabilityRule < ApplicationRecord
  belongs_to :member
  belongs_to :event_type, optional: true

  validates :day_of_week, inclusion: { in: 0..6 }, allow_nil: true
end
