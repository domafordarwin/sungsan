class AssignmentsController < ApplicationController
  before_action :set_event

  def create
    @assignment = @event.assignments.build(assignment_params)
    @assignment.assigned_by = Current.user
    @assignment.status = "pending"
    authorize @assignment

    if @assignment.save
      redirect_to event_path(@event), notice: "봉사자가 배정되었습니다."
    else
      redirect_to event_path(@event), alert: @assignment.errors.full_messages.join(", ")
    end
  end

  def destroy
    @assignment = @event.assignments.find(params[:id])
    authorize @assignment
    @assignment.update!(status: "canceled")
    redirect_to event_path(@event), notice: "배정이 취소되었습니다."
  end

  def recommend
    authorize Assignment, :recommend?
    @role = Role.find(params[:role_id])
    recommender = AssignmentRecommender.new(@event, @role)
    @candidates = recommender.candidates
    render partial: "assignments/candidates", locals: { candidates: @candidates, event: @event, role: @role }
  end

  private

  def set_event
    @event = Event.find(params[:event_id])
  end

  def assignment_params
    params.require(:assignment).permit(:member_id, :role_id)
  end
end
