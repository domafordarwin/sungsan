require "rails_helper"

RSpec.describe Auditable do
  let(:parish) { create(:parish) }

  before { Current.parish_id = parish.id }

  describe "after_create callback" do
    it "creates an audit log on create" do
      expect {
        create(:member, parish: parish)
      }.to change(AuditLog, :count).by(1)

      log = AuditLog.last
      expect(log.action).to eq("create")
      expect(log.auditable_type).to eq("Member")
    end
  end

  describe "after_update callback" do
    it "creates an audit log on update" do
      member = create(:member, parish: parish)

      expect {
        member.update!(name: "새이름")
      }.to change(AuditLog, :count).by(1)

      log = AuditLog.last
      expect(log.action).to eq("update")
      expect(log.changes_data).to have_key("name")
    end
  end

  describe "after_destroy callback" do
    it "creates an audit log on destroy" do
      member = create(:member, parish: parish)

      expect {
        member.destroy!
      }.to change(AuditLog, :count).by(1)

      expect(AuditLog.last.action).to eq("destroy")
    end
  end

  describe "error handling" do
    it "does not prevent main operation when audit fails" do
      allow(AuditLog).to receive(:create!).and_raise(StandardError.new("audit error"))

      expect {
        create(:member, parish: parish)
      }.not_to raise_error
    end
  end
end
