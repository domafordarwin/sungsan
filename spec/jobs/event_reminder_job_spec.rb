RSpec.describe EventReminderJob do
  let(:parish) { create(:parish) }
  let(:event_type) { create(:event_type, parish: parish) }
  let(:role) { create(:role, parish: parish) }
  let(:event) { create(:event, parish: parish, event_type: event_type, date: Date.current + 1.day, start_time: "09:00") }
  let(:member) { create(:member, parish: parish, active: true) }

  before { Current.parish_id = parish.id }

  it "creates reminder for tomorrow's accepted assignments" do
    create(:assignment, :accepted, event: event, role: role, member: member)

    expect { described_class.perform_now }.to change(Notification, :count).by(1)
    expect(Notification.last.subject).to include("리마인더")
  end

  it "skips non-tomorrow events" do
    far_event = create(:event, parish: parish, event_type: event_type, date: Date.current + 7.days, start_time: "09:00")
    create(:assignment, :accepted, event: far_event, role: role, member: member)
    expect { described_class.perform_now }.not_to change(Notification, :count)
  end
end
