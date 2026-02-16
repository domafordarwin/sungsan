class EventType < ApplicationRecord
  include ParishScoped
  include Auditable

  has_many :event_role_requirements, dependent: :destroy
  has_many :roles, through: :event_role_requirements
  has_many :events, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: { scope: :parish_id }

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:name) }

  def total_required_count
    event_role_requirements.sum(:required_count)
  end
end
