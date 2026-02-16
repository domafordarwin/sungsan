RSpec.describe RolePolicy, type: :policy do
  let(:parish) { create(:parish) }
  let(:admin) { create(:user, :admin, parish: parish) }
  let(:operator) { create(:user, :operator, parish: parish) }
  let(:member_user) { create(:user, :member_role, parish: parish) }
  let(:role) { create(:role, parish: parish) }

  permissions :index?, :show? do
    it "permits admin" do
      expect(described_class).to permit(admin, role)
    end

    it "permits operator" do
      expect(described_class).to permit(operator, role)
    end

    it "denies member" do
      expect(described_class).not_to permit(member_user, role)
    end
  end

  permissions :create?, :update?, :destroy? do
    it "permits admin" do
      expect(described_class).to permit(admin, role)
    end

    it "denies operator" do
      expect(described_class).not_to permit(operator, role)
    end

    it "denies member" do
      expect(described_class).not_to permit(member_user, role)
    end
  end
end
