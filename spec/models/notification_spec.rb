require "rails_helper"

RSpec.describe Notification do
  describe "validations" do
    it { is_expected.to validate_presence_of(:notification_type) }
    it { is_expected.to validate_inclusion_of(:notification_type).in_array(%w[assignment reminder announcement]) }
    it { is_expected.to validate_presence_of(:channel) }
    it { is_expected.to validate_inclusion_of(:channel).in_array(%w[email sms push]) }
    it { is_expected.to validate_inclusion_of(:status).in_array(%w[pending sent failed read]) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:parish) }
    it { is_expected.to belong_to(:recipient).class_name("Member").optional }
    it { is_expected.to belong_to(:sender).class_name("User").optional }
    it { is_expected.to belong_to(:related).optional }
  end
end
