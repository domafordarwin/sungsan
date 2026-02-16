class AuditLog < ApplicationRecord
  ACTIONS = %w[create update destroy login logout password_change].freeze

  belongs_to :parish, optional: true
  belongs_to :user, optional: true
  belongs_to :auditable, polymorphic: true

  validates :action, presence: true, inclusion: { in: ACTIONS }
  validates :auditable_type, presence: true
  validates :auditable_id, presence: true

  scope :recent, -> { order(created_at: :desc).limit(100) }
  scope :for_record, ->(type, id) { where(auditable_type: type, auditable_id: id) }
end
