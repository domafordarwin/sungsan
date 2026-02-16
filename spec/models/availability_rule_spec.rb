require "rails_helper"

RSpec.describe AvailabilityRule do
  describe "validations" do
    it { is_expected.to allow_value(0).for(:day_of_week) }
    it { is_expected.to allow_value(6).for(:day_of_week) }
    it { is_expected.to allow_value(nil).for(:day_of_week) }
    it { is_expected.not_to allow_value(7).for(:day_of_week) }
    it { is_expected.not_to allow_value(-1).for(:day_of_week) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:member) }
    it { is_expected.to belong_to(:event_type).optional }
  end
end
