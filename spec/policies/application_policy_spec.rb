require "rails_helper"

RSpec.describe ApplicationPolicy do
  let(:parish) { create(:parish) }
  let(:admin) { create(:user, :admin, parish: parish) }
  let(:member_user) { create(:user, :member_role, parish: parish) }
  let(:record) { create(:user, parish: parish) }

  subject { described_class }

  permissions :index?, :show?, :create?, :update?, :destroy? do
    it "denies access by default" do
      expect(subject).not_to permit(admin, record)
    end
  end

  describe "#admin?" do
    it "returns true for admin user" do
      policy = described_class.new(admin, record)
      expect(policy.admin?).to be true
    end

    it "returns false for member user" do
      policy = described_class.new(member_user, record)
      expect(policy.admin?).to be false
    end
  end

  describe "#operator_or_admin?" do
    let(:operator) { create(:user, :operator, parish: parish) }

    it "returns true for admin" do
      policy = described_class.new(admin, record)
      expect(policy.operator_or_admin?).to be true
    end

    it "returns true for operator" do
      policy = described_class.new(operator, record)
      expect(policy.operator_or_admin?).to be true
    end

    it "returns false for member" do
      policy = described_class.new(member_user, record)
      expect(policy.operator_or_admin?).to be false
    end
  end
end
