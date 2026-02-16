class Event < ApplicationRecord
  include ParishScoped
  include Auditable

  belongs_to :event_type
  has_many :assignments, dependent: :destroy
  has_many :attendance_records, dependent: :destroy

  validates :date, presence: true
  validates :start_time, presence: true

  scope :upcoming, -> { where("date >= ?", Date.current).order(:date, :start_time) }
  scope :past, -> { where("date < ?", Date.current).order(date: :desc) }
  scope :on_date, ->(date) { where(date: date) }
  scope :this_week, -> { where(date: Date.current.beginning_of_week..Date.current.end_of_week) }
  scope :this_month, -> { where(date: Date.current.beginning_of_month..Date.current.end_of_month) }

  def display_name
    title.presence || "#{event_type.name} (#{date.strftime('%m/%d')})"
  end
end
