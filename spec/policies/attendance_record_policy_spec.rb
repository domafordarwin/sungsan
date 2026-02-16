RSpec.describe AttendanceRecordPolicy, type: :policy do
  let(:parish) { create(:parish) }
  let(:admin) { create(:user, :admin, parish: parish) }
  let(:operator) { create(:user, :operator, parish: parish) }
  let(:member_user) { create(:user, :member_role, parish: parish) }
  let(:record) { AttendanceRecord.new }

  permissions :edit? do
    it "permits admin" do
      expect(described_class).to permit(admin, record)
    end

    it "permits operator" do
      expect(described_class).to permit(operator, record)
    end

    it "denies member" do
      expect(described_class).not_to permit(member_user, record)
    end
  end

  permissions :update? do
    it "permits admin" do
      expect(described_class).to permit(admin, record)
    end

    it "permits operator" do
      expect(described_class).to permit(operator, record)
    end

    it "denies member" do
      expect(described_class).not_to permit(member_user, record)
    end
  end
end
