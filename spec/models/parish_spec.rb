require "rails_helper"

RSpec.describe Parish do
  describe "validations" do
    subject { build(:parish) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name) }
  end

  describe "associations" do
    it { is_expected.to have_many(:users).dependent(:restrict_with_error) }
    it { is_expected.to have_many(:members).dependent(:restrict_with_error) }
    it { is_expected.to have_many(:roles).dependent(:destroy) }
    it { is_expected.to have_many(:event_types).dependent(:destroy) }
    it { is_expected.to have_many(:qualifications).dependent(:destroy) }
    it { is_expected.to have_many(:events).dependent(:destroy) }
    it { is_expected.to have_many(:notifications).dependent(:destroy) }
    it { is_expected.to have_many(:audit_logs) }
  end
end
