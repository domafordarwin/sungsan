require "rails_helper"

RSpec.describe AuditLog do
  describe "validations" do
    it { is_expected.to validate_presence_of(:action) }
    it { is_expected.to validate_inclusion_of(:action).in_array(%w[create update destroy]) }
    it { is_expected.to validate_presence_of(:auditable_type) }
    it { is_expected.to validate_presence_of(:auditable_id) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:parish).optional }
    it { is_expected.to belong_to(:user).optional }
    it { is_expected.to belong_to(:auditable) }
  end

  describe "scopes" do
    it ".recent returns last 100 logs ordered by created_at desc" do
      parish = create(:parish)
      member = create(:member, parish: parish)
      log = AuditLog.create!(action: "create", auditable: member, changes_data: {})
      expect(described_class.recent).to include(log)
    end

    it ".for_record filters by auditable type and id" do
      parish = create(:parish)
      member = create(:member, parish: parish)
      log = AuditLog.create!(action: "create", auditable: member, changes_data: {})
      expect(described_class.for_record("Member", member.id)).to eq([log])
    end
  end
end
