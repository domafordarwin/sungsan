class MemberRole < ApplicationRecord
  belongs_to :member
  belongs_to :role
  validates :role_id, uniqueness: { scope: :member_id }
end
