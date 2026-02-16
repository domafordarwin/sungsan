require "rails_helper"

RSpec.describe Role do
  describe "validations" do
    subject { build(:role) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name).scoped_to(:parish_id) }
    it { is_expected.to validate_numericality_of(:sort_order).only_integer.is_greater_than_or_equal_to(0) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:parish) }
    it { is_expected.to have_many(:event_role_requirements).dependent(:destroy) }
    it { is_expected.to have_many(:assignments).dependent(:restrict_with_error) }
  end

  describe "scopes" do
    let(:parish) { create(:parish) }

    before { Current.parish_id = parish.id }

    it ".ordered returns roles by sort_order" do
      role2 = create(:role, sort_order: 2, parish: parish)
      role1 = create(:role, sort_order: 1, parish: parish)
      expect(described_class.ordered).to eq([role1, role2])
    end
  end
end
