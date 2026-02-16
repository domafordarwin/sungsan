require "rails_helper"

RSpec.describe ParishScoped do
  describe "validations" do
    it "requires parish_id" do
      user = User.new(email_address: "test@example.com", name: "Test", password: "password123", role: "member")
      expect(user).not_to be_valid
      expect(user.errors[:parish_id]).to be_present
    end
  end

  describe "default_scope" do
    let(:parish1) { create(:parish, name: "본당1") }
    let(:parish2) { create(:parish, name: "본당2") }

    before do
      create(:role, name: "역할A", parish: parish1)
      create(:role, name: "역할B", parish: parish2)
    end

    it "scopes queries to current parish when Current.parish_id is set" do
      Current.parish_id = parish1.id
      expect(Role.all.map(&:name)).to eq(["역할A"])
    end

    it "returns all records when Current.parish_id is nil" do
      Current.parish_id = nil
      expect(Role.all.map(&:name)).to match_array(["역할A", "역할B"])
    end
  end

  describe ".unscoped_by_parish" do
    let(:parish1) { create(:parish, name: "본당A") }
    let(:parish2) { create(:parish, name: "본당B") }

    before do
      create(:role, name: "R1", parish: parish1)
      create(:role, name: "R2", parish: parish2)
      Current.parish_id = parish1.id
    end

    it "removes parish scope" do
      expect(Role.unscoped_by_parish.count).to eq(2)
    end
  end
end
