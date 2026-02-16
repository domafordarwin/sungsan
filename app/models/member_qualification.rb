class MemberQualification < ApplicationRecord
  include Auditable

  belongs_to :member
  belongs_to :qualification

  validates :acquired_date, presence: true
  validates :qualification_id, uniqueness: { scope: :member_id }

  def expired?
    expires_date.present? && expires_date < Date.current
  end

  def valid_qualification?
    !expired?
  end
end
