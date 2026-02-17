class SendNotificationJob < ApplicationJob
  queue_as :default

  def perform(assignment_id)
    assignment = Assignment.find_by(id: assignment_id)
    return unless assignment
    return if assignment.member.email.blank?

    AssignmentMailer.assignment_created(assignment).deliver_now
  rescue => e
    Rails.logger.error "SendNotificationJob failed for assignment #{assignment_id}: #{e.message}"
  end
end
