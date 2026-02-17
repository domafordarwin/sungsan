class Role < ApplicationRecord
  include ParishScoped
  include Auditable
  include SampleDataScoped

  has_many :event_role_requirements, dependent: :destroy
  has_many :assignments, dependent: :restrict_with_error
  has_many :member_roles, dependent: :destroy
  has_many :members, through: :member_roles

  validates :name, presence: true, uniqueness: { scope: :parish_id }
  validates :sort_order, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:sort_order) }
end
