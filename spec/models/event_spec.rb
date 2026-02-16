require "rails_helper"

RSpec.describe Event do
  describe "validations" do
    it { is_expected.to validate_presence_of(:date) }
    it { is_expected.to validate_presence_of(:start_time) }
  end

  describe "associations" do
    it { is_expected.to belong_to(:parish) }
    it { is_expected.to belong_to(:event_type) }
    it { is_expected.to have_many(:assignments).dependent(:destroy) }
    it { is_expected.to have_many(:attendance_records).dependent(:destroy) }
  end

  describe "scopes" do
    let(:parish) { create(:parish) }

    before { Current.parish_id = parish.id }

    it ".upcoming returns future events ordered by date" do
      upcoming = create(:event, :upcoming, parish: parish)
      create(:event, :past, parish: parish)
      expect(described_class.upcoming).to eq([upcoming])
    end

    it ".past returns past events ordered by date desc" do
      create(:event, :upcoming, parish: parish)
      past = create(:event, :past, parish: parish)
      expect(described_class.past).to eq([past])
    end

    it ".on_date returns events on given date" do
      today = create(:event, date: Date.current, parish: parish)
      create(:event, date: Date.current + 1.day, parish: parish)
      expect(described_class.on_date(Date.current)).to eq([today])
    end

    it ".this_week returns events in current week" do
      this_week = create(:event, date: Date.current, parish: parish)
      create(:event, date: Date.current + 2.weeks, parish: parish)
      expect(described_class.this_week).to eq([this_week])
    end

    it ".this_month returns events in current month" do
      this_month = create(:event, date: Date.current, parish: parish)
      create(:event, date: Date.current + 2.months, parish: parish)
      expect(described_class.this_month).to eq([this_month])
    end
  end

  describe "#display_name" do
    let(:parish) { create(:parish) }

    before { Current.parish_id = parish.id }

    it "returns event_type name and date when title is blank" do
      event = create(:event, parish: parish)
      expected = "#{event.event_type.name} (#{event.date.strftime('%m/%d')})"
      expect(event.display_name).to eq(expected)
    end
  end
end
