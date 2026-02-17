class AssignmentMailer < ApplicationMailer
  def assignment_created(assignment)
    @assignment = assignment
    @member = assignment.member
    @event = assignment.event
    @role = assignment.role
    @response_url = response_url(token: assignment.response_token)

    mail(
      to: @member.email,
      subject: "[성단매니저] #{@event.date.strftime('%m/%d')} #{@event.event_type.name} 배정 알림"
    )
  end

  def reminder(assignment)
    @assignment = assignment
    @member = assignment.member
    @event = assignment.event
    @role = assignment.role

    mail(
      to: @member.email,
      subject: "[성단매니저] 내일 미사 봉사 알림 - #{@event.event_type.name}"
    )
  end

  def substitute_request(assignment, candidate)
    @assignment = assignment
    @candidate = candidate
    @event = assignment.event
    @role = assignment.role

    mail(
      to: candidate.email,
      subject: "[성단매니저] 대타 봉사 요청 - #{@event.date.strftime('%m/%d')} #{@event.event_type.name}"
    )
  end
end
