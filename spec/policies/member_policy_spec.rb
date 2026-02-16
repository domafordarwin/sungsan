require "rails_helper"

RSpec.describe MemberPolicy do
  let(:parish) { create(:parish) }
  let(:admin) { create(:user, :admin, parish: parish) }
  let(:operator) { create(:user, :operator, parish: parish) }
  let(:member_user) { create(:user, :member_role, parish: parish) }
  let(:member_record) { create(:member, parish: parish, user: member_user) }
  let(:other_member) { create(:member, parish: parish) }

  subject { described_class }

  permissions :index? do
    it "grants access to admin" do
      expect(subject).to permit(admin, Member)
    end

    it "grants access to operator" do
      expect(subject).to permit(operator, Member)
    end

    it "denies access to member" do
      expect(subject).not_to permit(member_user, Member)
    end
  end

  permissions :show? do
    it "grants access to admin for any member" do
      expect(subject).to permit(admin, other_member)
    end

    it "grants access to operator for any member" do
      expect(subject).to permit(operator, other_member)
    end

    it "grants member access to own record" do
      expect(subject).to permit(member_user, member_record)
    end

    it "denies member access to other record" do
      expect(subject).not_to permit(member_user, other_member)
    end
  end

  permissions :create? do
    it "grants access to admin" do
      expect(subject).to permit(admin, Member.new)
    end

    it "denies access to operator" do
      expect(subject).not_to permit(operator, Member.new)
    end

    it "denies access to member" do
      expect(subject).not_to permit(member_user, Member.new)
    end
  end

  permissions :update? do
    it "grants access to admin" do
      expect(subject).to permit(admin, member_record)
    end

    it "grants access to operator" do
      expect(subject).to permit(operator, member_record)
    end

    it "denies access to member" do
      expect(subject).not_to permit(member_user, member_record)
    end
  end

  permissions :destroy? do
    it "grants access to admin" do
      expect(subject).to permit(admin, member_record)
    end

    it "denies access to operator" do
      expect(subject).not_to permit(operator, member_record)
    end

    it "denies access to member" do
      expect(subject).not_to permit(member_user, member_record)
    end
  end

  describe "Scope" do
    before do
      member_record
      other_member
    end

    it "returns all members for admin" do
      scope = described_class::Scope.new(admin, Member.unscoped_by_parish).resolve
      expect(scope.count).to eq(2)
    end

    it "returns all members for operator" do
      scope = described_class::Scope.new(operator, Member.unscoped_by_parish).resolve
      expect(scope.count).to eq(2)
    end

    it "returns only own record for member" do
      scope = described_class::Scope.new(member_user, Member.unscoped_by_parish).resolve
      expect(scope).to contain_exactly(member_record)
    end
  end
end
