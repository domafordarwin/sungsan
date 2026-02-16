class Member < ApplicationRecord
  include ParishScoped
  include Auditable
  include Maskable

  belongs_to :user, optional: true
  has_many :assignments, dependent: :restrict_with_error
  has_many :attendance_records, dependent: :restrict_with_error
  has_many :availability_rules, dependent: :destroy
  has_many :blackout_periods, dependent: :destroy
  has_many :member_qualifications, dependent: :destroy
  has_many :qualifications, through: :member_qualifications

  maskable_fields :phone, :email, :birth_date

  validates :name, presence: true
  validates :user_id, uniqueness: true, allow_nil: true
  validates :phone, format: { with: /\A\d{2,3}-\d{3,4}-\d{4}\z/ }, allow_blank: true

  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :baptized, -> { where(baptized: true) }
  scope :confirmed, -> { where(confirmed: true) }
  scope :by_district, ->(district) { where(district: district) }
end
