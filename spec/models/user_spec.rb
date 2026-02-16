require "rails_helper"

RSpec.describe User do
  describe "validations" do
    subject { build(:user) }

    it { is_expected.to validate_presence_of(:email_address) }
    it { is_expected.to validate_uniqueness_of(:email_address).case_insensitive }
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:role) }
    it { is_expected.to validate_inclusion_of(:role).in_array(%w[admin operator member]) }
    it { is_expected.to have_secure_password }
  end

  describe "associations" do
    it { is_expected.to belong_to(:parish) }
    it { is_expected.to have_many(:sessions).dependent(:destroy) }
    it { is_expected.to have_one(:member).dependent(:nullify) }
  end

  describe "role methods" do
    let(:admin) { build(:user, :admin) }
    let(:operator) { build(:user, :operator) }
    let(:member_user) { build(:user, :member_role) }

    it "admin? returns true for admin role" do
      expect(admin).to be_admin
    end

    it "operator? returns true for operator role" do
      expect(operator).to be_operator
    end

    it "member_role? returns true for member role" do
      expect(member_user).to be_member_role
    end
  end

  describe "normalizations" do
    it "normalizes email_address to lowercase stripped" do
      user = build(:user, email_address: "  Admin@Example.COM  ")
      expect(user.email_address).to eq("admin@example.com")
    end
  end
end
