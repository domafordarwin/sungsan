require "rails_helper"

RSpec.describe Qualification do
  describe "validations" do
    subject { build(:qualification) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name).scoped_to(:parish_id) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:parish) }
    it { is_expected.to have_many(:member_qualifications).dependent(:destroy) }
  end
end
