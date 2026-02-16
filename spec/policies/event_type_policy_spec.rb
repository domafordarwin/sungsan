RSpec.describe EventTypePolicy, type: :policy do
  let(:parish) { create(:parish) }
  let(:admin) { create(:user, :admin, parish: parish) }
  let(:operator) { create(:user, :operator, parish: parish) }
  let(:member_user) { create(:user, :member_role, parish: parish) }
  let(:event_type) { create(:event_type, parish: parish) }

  permissions :index?, :show? do
    it "permits admin" do
      expect(described_class).to permit(admin, event_type)
    end

    it "permits operator" do
      expect(described_class).to permit(operator, event_type)
    end

    it "denies member" do
      expect(described_class).not_to permit(member_user, event_type)
    end
  end

  permissions :create?, :update?, :destroy? do
    it "permits admin" do
      expect(described_class).to permit(admin, event_type)
    end

    it "denies operator" do
      expect(described_class).not_to permit(operator, event_type)
    end

    it "denies member" do
      expect(described_class).not_to permit(member_user, event_type)
    end
  end
end
