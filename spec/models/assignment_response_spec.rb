RSpec.describe Assignment, "response methods" do
  let(:parish) { create(:parish) }
  let(:event_type) { create(:event_type, parish: parish) }
  let(:role) { create(:role, parish: parish) }
  let(:event) { create(:event, parish: parish, event_type: event_type, date: Date.current + 7.days, start_time: "09:00") }
  let(:member) { create(:member, parish: parish, active: true) }
  let(:assignment) { create(:assignment, event: event, role: role, member: member, status: "pending") }

  before do
    Current.parish_id = parish.id
  end

  describe "#generate_response_token!" do
    it "generates a token" do
      assignment.generate_response_token!
      expect(assignment.response_token).to be_present
    end

    it "sets expiry to 72 hours from now" do
      freeze_time do
        assignment.generate_response_token!
        expect(assignment.response_token_expires_at).to eq(72.hours.from_now)
      end
    end

    it "generates unique tokens" do
      other = create(:assignment, event: event, role: role,
                     member: create(:member, parish: parish), status: "pending")
      assignment.generate_response_token!
      other.generate_response_token!
      expect(assignment.response_token).not_to eq(other.response_token)
    end
  end

  describe "#accept!" do
    it "sets status to accepted with responded_at" do
      assignment.accept!
      expect(assignment.status).to eq("accepted")
      expect(assignment.responded_at).to be_present
    end
  end

  describe "#decline!" do
    it "sets status to declined with reason" do
      assignment.decline!("개인 사정")
      expect(assignment.status).to eq("declined")
      expect(assignment.decline_reason).to eq("개인 사정")
      expect(assignment.responded_at).to be_present
    end

    it "works without reason" do
      assignment.decline!
      expect(assignment.status).to eq("declined")
      expect(assignment.decline_reason).to be_nil
    end
  end

  describe "#respondable?" do
    it "returns true for pending with valid token" do
      assignment.generate_response_token!
      expect(assignment.respondable?).to be true
    end

    it "returns false for non-pending" do
      assignment.generate_response_token!
      assignment.accept!
      expect(assignment.respondable?).to be false
    end

    it "returns false for expired token" do
      assignment.generate_response_token!
      assignment.update!(response_token_expires_at: 1.hour.ago)
      expect(assignment.respondable?).to be false
    end

    it "returns false without token" do
      expect(assignment.respondable?).to be false
    end
  end

  describe ".needing_substitute" do
    it "returns declined assignments without substitute" do
      declined = create(:assignment, :declined, event: event, role: role,
                        member: create(:member, parish: parish))
      expect(Assignment.needing_substitute).to include(declined)
    end

    it "excludes declined assignments with substitute" do
      declined = create(:assignment, :declined, event: event, role: role,
                        member: create(:member, parish: parish),
                        replaced_by: create(:member, parish: parish))
      expect(Assignment.needing_substitute).not_to include(declined)
    end
  end
end
