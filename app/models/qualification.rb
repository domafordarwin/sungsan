class Qualification < ApplicationRecord
  include ParishScoped

  has_many :member_qualifications, dependent: :destroy

  validates :name, presence: true, uniqueness: { scope: :parish_id }
end
