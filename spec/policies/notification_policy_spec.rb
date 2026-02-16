RSpec.describe NotificationPolicy, type: :policy do
  let(:parish) { create(:parish) }
  let(:admin) { create(:user, :admin, parish: parish) }
  let(:operator) { create(:user, :operator, parish: parish) }
  let(:member_user) { create(:user, :member_role, parish: parish) }
  let(:notification) { Notification.new(parish: parish) }

  permissions :index?, :show?, :create? do
    it "permits admin" do
      expect(described_class).to permit(admin, notification)
    end

    it "permits operator" do
      expect(described_class).to permit(operator, notification)
    end

    it "denies member" do
      expect(described_class).not_to permit(member_user, notification)
    end
  end
end
