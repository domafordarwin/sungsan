class BlackoutPeriod < ApplicationRecord
  belongs_to :member

  validates :start_date, presence: true
  validates :end_date, presence: true
  validate :end_date_after_start_date

  scope :active_on, ->(date) { where("start_date <= ? AND end_date >= ?", date, date) }

  private

  def end_date_after_start_date
    return if start_date.blank? || end_date.blank?
    errors.add(:end_date, "은 시작일 이후여야 합니다") if end_date < start_date
  end
end
