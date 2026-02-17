class Event < ApplicationRecord
  include ParishScoped
  include Auditable
  include Paginatable
  include SampleDataScoped

  belongs_to :event_type
  has_many :assignments, dependent: :destroy
  has_many :attendance_records, dependent: :destroy

  validates :date, presence: true
  validates :start_time, presence: true
  validate :end_time_after_start_time

  scope :upcoming, -> { where("date >= ?", Date.current).order(:date, :start_time) }
  scope :past, -> { where("date < ?", Date.current).order(date: :desc) }
  scope :on_date, ->(date) { where(date: date) }
  scope :this_week, -> { where(date: Date.current.beginning_of_week..Date.current.end_of_week) }
  scope :this_month, -> { where(date: Date.current.beginning_of_month..Date.current.end_of_month) }
  scope :by_event_type, ->(event_type_id) { where(event_type_id: event_type_id) }
  scope :in_date_range, ->(from, to) { where(date: from..to) }
  scope :ordered, -> { order(:date, :start_time) }

  def display_name
    title.presence || "#{event_type.name} (#{date.strftime('%m/%d')})"
  end

  def has_assignments?
    assignments.exists?
  end

  def assignment_summary
    event_type.event_role_requirements.includes(:role).map do |req|
      assigned = assignments.where(role_id: req.role_id).count
      { role: req.role, required: req.required_count, assigned: assigned }
    end
  end

  private

  def end_time_after_start_time
    return if end_time.blank? || start_time.blank?
    if end_time <= start_time
      errors.add(:end_time, "은(는) 시작 시간 이후여야 합니다")
    end
  end
end
