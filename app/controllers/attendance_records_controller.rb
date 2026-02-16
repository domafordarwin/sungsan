class AttendanceRecordsController < ApplicationController
  before_action :set_event

  def edit
    authorize AttendanceRecord
    @assignments = @event.assignments.where(status: %w[accepted pending])
                         .includes(:member, :role)
                         .order("members.name")
    @records = @event.attendance_records.index_by(&:member_id)
  end

  def update
    authorize AttendanceRecord

    attendance_params.each do |member_id, attrs|
      next if attrs[:status].blank?

      record = @event.attendance_records.find_or_initialize_by(member_id: member_id)
      record.assign_attributes(
        status: attrs[:status],
        reason: attrs[:reason],
        assignment_id: attrs[:assignment_id],
        recorded_by: Current.user
      )
      record.save!
    end

    redirect_to event_path(@event), notice: "출결이 기록되었습니다."
  end

  private

  def set_event
    @event = Event.find(params[:event_id])
  end

  def attendance_params
    params.require(:attendance).permit!
  end
end
