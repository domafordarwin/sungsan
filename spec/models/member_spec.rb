require "rails_helper"

RSpec.describe Member do
  describe "validations" do
    subject { build(:member) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:user_id).allow_nil }
    it { is_expected.to allow_value("010-1234-5678").for(:phone) }
    it { is_expected.to allow_value("02-123-4567").for(:phone) }
    it { is_expected.to allow_value("").for(:phone) }
    it { is_expected.not_to allow_value("invalid").for(:phone) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:parish) }
    it { is_expected.to belong_to(:user).optional }
    it { is_expected.to have_many(:assignments).dependent(:restrict_with_error) }
    it { is_expected.to have_many(:attendance_records).dependent(:restrict_with_error) }
    it { is_expected.to have_many(:availability_rules).dependent(:destroy) }
    it { is_expected.to have_many(:blackout_periods).dependent(:destroy) }
    it { is_expected.to have_many(:member_qualifications).dependent(:destroy) }
    it { is_expected.to have_many(:qualifications).through(:member_qualifications) }
  end

  describe "scopes" do
    let(:parish) { create(:parish) }

    before do
      Current.parish_id = parish.id
    end

    it ".active returns only active members" do
      active = create(:member, :active, parish: parish)
      create(:member, :inactive, parish: parish)
      expect(described_class.active).to eq([active])
    end

    it ".inactive returns only inactive members" do
      create(:member, :active, parish: parish)
      inactive = create(:member, :inactive, parish: parish)
      expect(described_class.inactive).to eq([inactive])
    end

    it ".baptized returns only baptized members" do
      baptized = create(:member, :baptized, parish: parish)
      create(:member, baptized: false, parish: parish)
      expect(described_class.baptized).to eq([baptized])
    end

    it ".confirmed returns only confirmed members" do
      confirmed = create(:member, :confirmed, parish: parish)
      create(:member, confirmed: false, parish: parish)
      expect(described_class.confirmed).to eq([confirmed])
    end

    it ".by_district filters by district" do
      member1 = create(:member, district: "1구역", parish: parish)
      create(:member, district: "2구역", parish: parish)
      expect(described_class.by_district("1구역")).to eq([member1])
    end
  end

  describe "concerns" do
    it "includes ParishScoped" do
      expect(described_class.ancestors).to include(ParishScoped)
    end

    it "includes Auditable" do
      expect(described_class.ancestors).to include(Auditable)
    end

    it "includes Maskable" do
      expect(described_class.ancestors).to include(Maskable)
    end
  end
end
