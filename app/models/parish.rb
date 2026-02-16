class Parish < ApplicationRecord
  has_many :users, dependent: :restrict_with_error
  has_many :members, dependent: :restrict_with_error
  has_many :roles, dependent: :destroy
  has_many :event_types, dependent: :destroy
  has_many :qualifications, dependent: :destroy
  has_many :events, dependent: :destroy
  has_many :notifications, dependent: :destroy
  has_many :audit_logs

  validates :name, presence: true, uniqueness: true
end
