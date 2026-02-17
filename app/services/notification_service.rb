class NotificationService
  def self.assignment_created(assignment)
    Notification.create!(
      parish_id: assignment.event.parish_id,
      recipient: assignment.member,
      sender_id: assignment.assigned_by_id,
      notification_type: "assignment",
      channel: "email",
      subject: "봉사 배정 알림",
      body: "#{assignment.event.display_name} - #{assignment.role.name}에 배정되었습니다.",
      status: "pending",
      related: assignment
    )

    SendNotificationJob.perform_later(assignment.id) if assignment.member.email.present?
  end

  def self.send_reminder(assignment)
    return if assignment.member.email.blank?

    AssignmentMailer.reminder(assignment).deliver_later
  end
end
