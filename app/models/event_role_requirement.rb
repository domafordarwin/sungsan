class EventRoleRequirement < ApplicationRecord
  include Auditable

  belongs_to :event_type
  belongs_to :role

  validates :required_count, presence: true,
    numericality: { only_integer: true, greater_than: 0 }
  validates :role_id, uniqueness: { scope: :event_type_id }
end
