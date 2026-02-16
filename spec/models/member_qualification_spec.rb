require "rails_helper"

RSpec.describe MemberQualification do
  describe "validations" do
    subject { build(:member_qualification) }

    it { is_expected.to validate_presence_of(:acquired_date) }
    it { is_expected.to validate_uniqueness_of(:qualification_id).scoped_to(:member_id) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:member) }
    it { is_expected.to belong_to(:qualification) }
  end

  describe "#expired?" do
    it "returns true when expires_date is past" do
      mq = build(:member_qualification, expires_date: Date.current - 1.day)
      expect(mq).to be_expired
    end

    it "returns false when expires_date is future" do
      mq = build(:member_qualification, expires_date: Date.current + 1.day)
      expect(mq).not_to be_expired
    end

    it "returns false when expires_date is nil" do
      mq = build(:member_qualification, expires_date: nil)
      expect(mq).not_to be_expired
    end
  end

  describe "#valid_qualification?" do
    it "returns true when not expired" do
      mq = build(:member_qualification, expires_date: Date.current + 1.day)
      expect(mq).to be_valid_qualification
    end

    it "returns false when expired" do
      mq = build(:member_qualification, expires_date: Date.current - 1.day)
      expect(mq).not_to be_valid_qualification
    end
  end
end
