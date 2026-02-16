class AssignmentReminderJob < ApplicationJob
  queue_as :default

  def perform
    Assignment.pending
              .where("assignments.created_at < ?", 48.hours.ago)
              .joins(:event)
              .where("events.date >= ?", Date.current)
              .includes(:member, :role, event: :event_type)
              .find_each do |assignment|
      Notification.create!(
        parish_id: assignment.event.parish_id,
        recipient: assignment.member,
        notification_type: "reminder",
        channel: "email",
        subject: "봉사 배정 응답 리마인더",
        body: "#{assignment.event.display_name} - #{assignment.role.name} 배정에 응답해 주세요.",
        status: "pending",
        related: assignment
      )
    end
  end
end
