class EventType < ApplicationRecord
  include ParishScoped

  has_many :event_role_requirements, dependent: :destroy
  has_many :roles, through: :event_role_requirements
  has_many :events, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: { scope: :parish_id }

  scope :active, -> { where(active: true) }
end
