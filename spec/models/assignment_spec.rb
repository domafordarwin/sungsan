require "rails_helper"

RSpec.describe Assignment do
  describe "validations" do
    subject { build(:assignment) }

    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_inclusion_of(:status).in_array(%w[pending accepted declined replaced canceled]) }
    it { is_expected.to validate_uniqueness_of(:member_id).scoped_to([:event_id, :role_id]) }
    it { is_expected.to validate_uniqueness_of(:response_token).allow_nil }
  end

  describe "associations" do
    it { is_expected.to belong_to(:event) }
    it { is_expected.to belong_to(:role) }
    it { is_expected.to belong_to(:member) }
    it { is_expected.to belong_to(:replaced_by).class_name("Member").optional }
    it { is_expected.to belong_to(:assigned_by).class_name("User").optional }
    it { is_expected.to have_one(:attendance_record) }
  end

  describe "status methods" do
    it "#accepted? returns true when status is accepted" do
      assignment = build(:assignment, :accepted)
      expect(assignment).to be_accepted
    end

    it "#pending? returns true when status is pending" do
      assignment = build(:assignment, :pending)
      expect(assignment).to be_pending
    end

    it "#declined? returns true when status is declined" do
      assignment = build(:assignment, :declined)
      expect(assignment).to be_declined
    end
  end

  describe "scopes" do
    let(:parish) { create(:parish) }

    before { Current.parish_id = parish.id }

    it ".pending returns pending assignments" do
      pending = create(:assignment, :pending)
      create(:assignment, :accepted)
      expect(described_class.pending).to eq([pending])
    end

    it ".accepted returns accepted assignments" do
      create(:assignment, :pending)
      accepted = create(:assignment, :accepted)
      expect(described_class.accepted).to eq([accepted])
    end

    it ".declined returns declined assignments" do
      create(:assignment, :pending)
      declined = create(:assignment, :declined)
      expect(described_class.declined).to eq([declined])
    end

    it ".for_member returns assignments for given member" do
      assignment = create(:assignment)
      create(:assignment)
      expect(described_class.for_member(assignment.member)).to eq([assignment])
    end

    it ".for_event returns assignments for given event" do
      assignment = create(:assignment)
      create(:assignment)
      expect(described_class.for_event(assignment.event)).to eq([assignment])
    end

    it ".for_role returns assignments for given role" do
      assignment = create(:assignment)
      create(:assignment)
      expect(described_class.for_role(assignment.role)).to eq([assignment])
    end
  end
end
