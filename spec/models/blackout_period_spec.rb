require "rails_helper"

RSpec.describe BlackoutPeriod do
  describe "validations" do
    it { is_expected.to validate_presence_of(:start_date) }
    it { is_expected.to validate_presence_of(:end_date) }

    it "validates end_date is after start_date" do
      period = build(:blackout_period, start_date: Date.current, end_date: Date.current - 1.day)
      expect(period).not_to be_valid
      expect(period.errors[:end_date]).to include("은 시작일 이후여야 합니다")
    end

    it "is valid when end_date equals start_date" do
      period = build(:blackout_period, start_date: Date.current, end_date: Date.current)
      expect(period).to be_valid
    end
  end

  describe "associations" do
    it { is_expected.to belong_to(:member) }
  end

  describe "scopes" do
    it ".active_on returns periods covering given date" do
      member = create(:member)
      active = create(:blackout_period, member: member, start_date: Date.current - 1.day, end_date: Date.current + 1.day)
      create(:blackout_period, member: member, start_date: Date.current + 5.days, end_date: Date.current + 10.days)
      expect(described_class.active_on(Date.current)).to eq([active])
    end
  end
end
