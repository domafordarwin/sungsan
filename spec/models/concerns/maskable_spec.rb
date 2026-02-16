require "rails_helper"

RSpec.describe Maskable do
  describe ".mask_phone" do
    it "masks middle digits of phone number" do
      expect(described_class.mask_phone("010-1234-5678")).to eq("010-****-5678")
    end

    it "returns blank phone as-is" do
      expect(described_class.mask_phone("")).to eq("")
    end

    it "returns nil phone as-is" do
      expect(described_class.mask_phone(nil)).to be_nil
    end
  end

  describe ".mask_email" do
    it "masks local part of email" do
      expect(described_class.mask_email("user@example.com")).to eq("us***@example.com")
    end

    it "returns blank email as-is" do
      expect(described_class.mask_email("")).to eq("")
    end

    it "returns nil email as-is" do
      expect(described_class.mask_email(nil)).to be_nil
    end
  end

  describe ".mask_date" do
    it "masks month and day of date" do
      date = Date.new(2000, 3, 15)
      expect(described_class.mask_date(date)).to eq("2000-**-**")
    end

    it "returns nil date as-is" do
      expect(described_class.mask_date(nil)).to be_nil
    end
  end

  describe ".mask_value" do
    let(:admin) { build(:user, :admin) }
    let(:member_user) { build(:user, :member_role) }

    it "returns unmasked value for admin users" do
      expect(described_class.mask_value(:phone, "010-1234-5678", admin)).to eq("010-1234-5678")
    end

    it "returns masked value for non-admin users" do
      expect(described_class.mask_value(:phone, "010-1234-5678", member_user)).to eq("010-****-5678")
    end

    it "returns unmasked value when value is blank" do
      expect(described_class.mask_value(:phone, nil, member_user)).to be_nil
    end
  end

  describe "instance methods on Member" do
    let(:parish) { create(:parish) }
    let(:member) { create(:member, parish: parish, phone: "010-1234-5678", email: "test@example.com", birth_date: Date.new(1990, 5, 20)) }

    before { Current.parish_id = parish.id }

    it "defines masked_phone method" do
      Current.user = build(:user, :member_role)
      expect(member.masked_phone).to eq("010-****-5678")
    end

    it "defines masked_email method" do
      Current.user = build(:user, :member_role)
      expect(member.masked_email).to eq("te***@example.com")
    end

    it "defines masked_birth_date method" do
      Current.user = build(:user, :member_role)
      expect(member.masked_birth_date).to eq("1990-**-**")
    end
  end
end
