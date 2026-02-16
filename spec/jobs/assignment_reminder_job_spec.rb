RSpec.describe AssignmentReminderJob do
  let(:parish) { create(:parish) }
  let(:event_type) { create(:event_type, parish: parish) }
  let(:role) { create(:role, parish: parish) }
  let(:event) { create(:event, parish: parish, event_type: event_type, date: Date.current + 3.days, start_time: "09:00") }
  let(:member) { create(:member, parish: parish, active: true) }

  before { Current.parish_id = parish.id }

  it "creates reminder for overdue pending assignments" do
    assignment = create(:assignment, event: event, role: role, member: member, status: "pending")
    assignment.update_column(:created_at, 3.days.ago)

    expect { described_class.perform_now }.to change(Notification, :count).by(1)
    expect(Notification.last.notification_type).to eq("reminder")
  end

  it "skips recent pending assignments" do
    create(:assignment, event: event, role: role, member: member, status: "pending")
    expect { described_class.perform_now }.not_to change(Notification, :count)
  end
end
