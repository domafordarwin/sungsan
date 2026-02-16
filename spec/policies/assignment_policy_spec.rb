RSpec.describe AssignmentPolicy, type: :policy do
  let(:parish) { create(:parish) }
  let(:admin) { create(:user, :admin, parish: parish) }
  let(:operator) { create(:user, :operator, parish: parish) }
  let(:member_user) { create(:user, :member_role, parish: parish) }
  let(:event_type) { create(:event_type, parish: parish) }
  let(:event) { create(:event, parish: parish, event_type: event_type) }
  let(:role) { create(:role, parish: parish) }
  let(:member) { create(:member, parish: parish) }
  let(:assignment) { create(:assignment, event: event, role: role, member: member) }

  permissions :create? do
    it "permits admin" do
      expect(described_class).to permit(admin, assignment)
    end

    it "permits operator" do
      expect(described_class).to permit(operator, assignment)
    end

    it "denies member" do
      expect(described_class).not_to permit(member_user, assignment)
    end
  end

  permissions :destroy? do
    it "permits admin" do
      expect(described_class).to permit(admin, assignment)
    end

    it "permits operator" do
      expect(described_class).to permit(operator, assignment)
    end

    it "denies member" do
      expect(described_class).not_to permit(member_user, assignment)
    end
  end
end
