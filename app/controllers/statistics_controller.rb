class StatisticsController < ApplicationController
  def index
    authorize :statistics, :index?

    @period = params[:period] || "month"
    @date_range = calculate_date_range

    # 참여율: accepted / (accepted + declined + pending)
    total = Assignment.joins(:event).where(events: { date: @date_range }).where.not(status: "canceled")
    @total_assignments = total.count
    @accepted_count = total.where(status: "accepted").count
    @declined_count = total.where(status: "declined").count
    @participation_rate = @total_assignments > 0 ? (@accepted_count * 100.0 / @total_assignments).round(1) : 0

    # 결석률: absent / total_attendance
    attendance_total = AttendanceRecord.joins(:event).where(events: { date: @date_range })
    @attendance_count = attendance_total.count
    @absent_count = attendance_total.where(status: "absent").count
    @absence_rate = @attendance_count > 0 ? (@absent_count * 100.0 / @attendance_count).round(1) : 0

    # 월별 봉사 횟수 (최근 6개월)
    @monthly_stats = (0..5).map do |i|
      month_start = i.months.ago.beginning_of_month.to_date
      month_end = i.months.ago.end_of_month.to_date
      count = Assignment.joins(:event)
                        .where(events: { date: month_start..month_end })
                        .where(status: "accepted").count
      { month: month_start.strftime("%Y-%m"), count: count }
    end.reverse

    # 역할별 통계
    @role_stats = Role.where(active: true).map do |role|
      assigned = Assignment.where(role: role).joins(:event)
                           .where(events: { date: @date_range })
                           .where.not(status: "canceled").count
      accepted = Assignment.where(role: role, status: "accepted").joins(:event)
                           .where(events: { date: @date_range }).count
      { role: role, assigned: assigned, accepted: accepted }
    end
  end

  private

  def calculate_date_range
    case @period
    when "week"
      Date.current.beginning_of_week..Date.current.end_of_week
    when "month"
      Date.current.beginning_of_month..Date.current.end_of_month
    when "quarter"
      Date.current.beginning_of_quarter..Date.current.end_of_quarter
    else
      Date.current.beginning_of_month..Date.current.end_of_month
    end
  end
end
