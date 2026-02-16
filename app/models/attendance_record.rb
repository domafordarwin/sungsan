class AttendanceRecord < ApplicationRecord
  include Auditable

  STATUSES = %w[present late absent excused replaced].freeze

  belongs_to :event
  belongs_to :member
  belongs_to :assignment, optional: true
  belongs_to :recorded_by, class_name: "User", optional: true

  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :member_id, uniqueness: {
    scope: :event_id,
    message: "이미 출결이 기록되어 있습니다"
  }

  scope :present_or_late, -> { where(status: %w[present late]) }
end
