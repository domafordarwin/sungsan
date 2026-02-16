require "rails_helper"

RSpec.describe EventRoleRequirement do
  describe "validations" do
    subject { build(:event_role_requirement) }

    it { is_expected.to validate_presence_of(:required_count) }
    it { is_expected.to validate_numericality_of(:required_count).only_integer.is_greater_than(0) }
    it { is_expected.to validate_uniqueness_of(:role_id).scoped_to(:event_type_id) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:event_type) }
    it { is_expected.to belong_to(:role) }
  end
end
