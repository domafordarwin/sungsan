class Assignment < ApplicationRecord
  include Auditable

  STATUSES = %w[pending accepted declined replaced canceled].freeze

  belongs_to :event
  belongs_to :role
  belongs_to :member
  belongs_to :replaced_by, class_name: "Member", optional: true
  belongs_to :assigned_by, class_name: "User", optional: true
  has_one :attendance_record

  validates :status, presence: true, inclusion: { in: STATUSES }
  validates :member_id, uniqueness: {
    scope: [:event_id, :role_id],
    message: "이미 같은 역할에 배정되어 있습니다"
  }
  validates :response_token, uniqueness: true, allow_nil: true

  scope :pending, -> { where(status: "pending") }
  scope :accepted, -> { where(status: "accepted") }
  scope :declined, -> { where(status: "declined") }
  scope :for_member, ->(member) { where(member: member) }
  scope :for_event, ->(event) { where(event: event) }
  scope :for_role, ->(role) { where(role: role) }

  def accepted?
    status == "accepted"
  end

  def pending?
    status == "pending"
  end

  def declined?
    status == "declined"
  end

  def token_valid?
    response_token.present? &&
      response_token_expires_at.present? &&
      response_token_expires_at > Time.current
  end
end
