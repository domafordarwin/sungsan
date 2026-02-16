RSpec.describe EventPolicy, type: :policy do
  let(:parish) { create(:parish) }
  let(:admin) { create(:user, :admin, parish: parish) }
  let(:operator) { create(:user, :operator, parish: parish) }
  let(:member_user) { create(:user, :member_role, parish: parish) }
  let(:event_type) { create(:event_type, parish: parish) }
  let(:event) { create(:event, parish: parish, event_type: event_type) }

  permissions :index?, :show? do
    it "permits admin" do
      expect(described_class).to permit(admin, event)
    end

    it "permits operator" do
      expect(described_class).to permit(operator, event)
    end

    it "denies member" do
      expect(described_class).not_to permit(member_user, event)
    end
  end

  permissions :create?, :update? do
    it "permits admin" do
      expect(described_class).to permit(admin, event)
    end

    it "permits operator" do
      expect(described_class).to permit(operator, event)
    end

    it "denies member" do
      expect(described_class).not_to permit(member_user, event)
    end
  end

  permissions :destroy? do
    it "permits admin" do
      expect(described_class).to permit(admin, event)
    end

    it "denies operator" do
      expect(described_class).not_to permit(operator, event)
    end

    it "denies member" do
      expect(described_class).not_to permit(member_user, event)
    end
  end
end
