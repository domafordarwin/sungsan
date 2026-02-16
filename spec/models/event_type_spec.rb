require "rails_helper"

RSpec.describe EventType do
  describe "validations" do
    subject { build(:event_type) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name).scoped_to(:parish_id) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:parish) }
    it { is_expected.to have_many(:event_role_requirements).dependent(:destroy) }
    it { is_expected.to have_many(:roles).through(:event_role_requirements) }
    it { is_expected.to have_many(:events).dependent(:restrict_with_error) }
  end
end
