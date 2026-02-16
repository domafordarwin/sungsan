RSpec.describe NotificationService do
  let(:parish) { create(:parish) }
  let(:event_type) { create(:event_type, parish: parish) }
  let(:role) { create(:role, parish: parish) }
  let(:event) { create(:event, parish: parish, event_type: event_type, date: Date.current + 7.days, start_time: "09:00") }
  let(:member) { create(:member, parish: parish, active: true) }
  let(:admin) { create(:user, :admin, parish: parish) }

  before { Current.parish_id = parish.id }

  describe ".assignment_created" do
    it "creates an assignment notification" do
      assignment = create(:assignment, event: event, role: role, member: member, assigned_by: admin)

      expect {
        described_class.assignment_created(assignment)
      }.to change(Notification, :count).by(1)

      n = Notification.last
      expect(n.notification_type).to eq("assignment")
      expect(n.recipient).to eq(member)
      expect(n.related).to eq(assignment)
      expect(n.status).to eq("pending")
    end
  end
end
