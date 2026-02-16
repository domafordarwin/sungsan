class EventReminderJob < ApplicationJob
  queue_as :default

  def perform
    tomorrow = Date.current + 1.day
    Event.where(date: tomorrow).includes(:assignments).find_each do |event|
      event.assignments.accepted.includes(:member, :role).each do |assignment|
        Notification.create!(
          parish_id: event.parish_id,
          recipient: assignment.member,
          notification_type: "reminder",
          channel: "email",
          subject: "내일 봉사 리마인더",
          body: "내일 #{event.start_time.strftime('%H:%M')} #{event.event_type.name} - #{assignment.role.name} 봉사가 있습니다.",
          status: "pending",
          related: assignment
        )
      end
    end
  end
end
