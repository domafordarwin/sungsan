require "rails_helper"

RSpec.describe AttendanceRecord do
  describe "validations" do
    subject { build(:attendance_record) }

    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_inclusion_of(:status).in_array(%w[present late absent excused replaced]) }
    it { is_expected.to validate_uniqueness_of(:member_id).scoped_to(:event_id) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:event) }
    it { is_expected.to belong_to(:member) }
    it { is_expected.to belong_to(:assignment).optional }
    it { is_expected.to belong_to(:recorded_by).class_name("User").optional }
  end

  describe "scopes" do
    it ".present_or_late returns present and late records" do
      present_record = create(:attendance_record, :present)
      late_record = create(:attendance_record, :late)
      create(:attendance_record, :absent)
      expect(described_class.present_or_late).to match_array([present_record, late_record])
    end
  end
end
