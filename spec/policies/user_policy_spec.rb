require "rails_helper"

RSpec.describe UserPolicy do
  let(:parish) { create(:parish) }
  let(:admin) { create(:user, :admin, parish: parish) }
  let(:operator) { create(:user, :operator, parish: parish) }
  let(:member_user) { create(:user, :member_role, parish: parish) }
  let(:other_user) { create(:user, :member_role, parish: parish) }

  subject { described_class }

  permissions :index? do
    it "grants access to admin" do
      expect(subject).to permit(admin, User)
    end

    it "denies access to operator" do
      expect(subject).not_to permit(operator, User)
    end

    it "denies access to member" do
      expect(subject).not_to permit(member_user, User)
    end
  end

  permissions :show? do
    it "grants access to admin for any user" do
      expect(subject).to permit(admin, other_user)
    end

    it "grants access to member for self" do
      expect(subject).to permit(member_user, member_user)
    end

    it "denies access to member for other user" do
      expect(subject).not_to permit(member_user, other_user)
    end
  end

  permissions :create?, :update? do
    it "grants access to admin" do
      expect(subject).to permit(admin, User.new)
    end

    it "denies access to operator" do
      expect(subject).not_to permit(operator, User.new)
    end

    it "denies access to member" do
      expect(subject).not_to permit(member_user, User.new)
    end
  end

  permissions :destroy? do
    it "grants admin access for other users" do
      expect(subject).to permit(admin, other_user)
    end

    it "denies admin from deleting self" do
      expect(subject).not_to permit(admin, admin)
    end

    it "denies operator" do
      expect(subject).not_to permit(operator, other_user)
    end

    it "denies member" do
      expect(subject).not_to permit(member_user, other_user)
    end
  end

  describe "Scope" do
    before do
      admin
      operator
      member_user
      other_user
    end

    it "returns all users for admin" do
      scope = described_class::Scope.new(admin, User.unscoped_by_parish).resolve
      expect(scope.count).to eq(4)
    end

    it "returns only self for member" do
      scope = described_class::Scope.new(member_user, User.unscoped_by_parish).resolve
      expect(scope).to contain_exactly(member_user)
    end
  end
end
