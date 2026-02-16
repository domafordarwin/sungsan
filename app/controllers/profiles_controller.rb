class ProfilesController < ApplicationController
  def show
    @member = Current.user.member
    if @member.nil?
      redirect_to root_path, alert: "연결된 봉사자 정보가 없습니다."
      return
    end

    @recent_assignments = @member.assignments.includes(:event, :role)
                                 .order("events.date DESC").limit(10)
    @attendance_records = @member.attendance_records.includes(:event)
                                 .order("events.date DESC").limit(10)
  end

  private

  def skip_authorization?
    true
  end
end
