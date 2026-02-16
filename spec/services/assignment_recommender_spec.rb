RSpec.describe AssignmentRecommender do
  let(:parish) { create(:parish) }
  let(:event_type) { create(:event_type, parish: parish) }
  let(:role) { create(:role, parish: parish, requires_baptism: false, requires_confirmation: false) }
  let(:event) { create(:event, parish: parish, event_type: event_type, date: Date.current + 7.days, start_time: "09:00") }

  before do
    Current.parish_id = parish.id
  end

  describe "#candidates" do
    it "returns active members only" do
      active = create(:member, parish: parish, active: true, name: "활성")
      create(:member, parish: parish, active: false, name: "비활성")

      result = described_class.new(event, role).candidates
      names = result.map { |c| c[:member].name }
      expect(names).to include("활성")
      expect(names).not_to include("비활성")
    end

    it "filters by baptism requirement" do
      baptism_role = create(:role, parish: parish, name: "세례역할", requires_baptism: true)
      baptized = create(:member, parish: parish, active: true, baptized: true, name: "세례자")
      create(:member, parish: parish, active: true, baptized: false, name: "비세례자")

      result = described_class.new(event, baptism_role).candidates
      names = result.map { |c| c[:member].name }
      expect(names).to include("세례자")
      expect(names).not_to include("비세례자")
    end

    it "filters by confirmation requirement" do
      confirm_role = create(:role, parish: parish, name: "견진역할", requires_confirmation: true)
      confirmed = create(:member, parish: parish, active: true, confirmed: true, name: "견진자")
      create(:member, parish: parish, active: true, confirmed: false, name: "미견진자")

      result = described_class.new(event, confirm_role).candidates
      names = result.map { |c| c[:member].name }
      expect(names).to include("견진자")
      expect(names).not_to include("미견진자")
    end

    it "excludes already assigned members" do
      assigned_member = create(:member, parish: parish, active: true, name: "이미배정")
      create(:member, parish: parish, active: true, name: "미배정")
      create(:assignment, event: event, member: assigned_member, role: role, status: "pending")

      result = described_class.new(event, role).candidates
      names = result.map { |c| c[:member].name }
      expect(names).not_to include("이미배정")
      expect(names).to include("미배정")
    end

    it "excludes blackout period members" do
      blackout_member = create(:member, parish: parish, active: true, name: "불가기간")
      create(:member, parish: parish, active: true, name: "가능")
      create(:blackout_period, member: blackout_member,
             start_date: event.date - 1.day, end_date: event.date + 1.day)

      result = described_class.new(event, role).candidates
      names = result.map { |c| c[:member].name }
      expect(names).not_to include("불가기간")
      expect(names).to include("가능")
    end

    it "scores by recent assignment count (less assignments = higher score)" do
      busy = create(:member, parish: parish, active: true, name: "바쁜봉사자")
      free = create(:member, parish: parish, active: true, name: "여유봉사자")
      other_event = create(:event, parish: parish, event_type: event_type, date: Date.current + 1.day, start_time: "09:00")
      3.times { create(:assignment, event: other_event, member: busy, role: role, status: "accepted") }

      result = described_class.new(event, role).candidates
      scores = result.map { |c| [c[:member].name, c[:score]] }.to_h
      expect(scores["여유봉사자"]).to be > scores["바쁜봉사자"]
    end

    it "gives bonus for availability rule match" do
      available = create(:member, parish: parish, active: true, name: "가용")
      create(:member, parish: parish, active: true, name: "규칙없음")
      create(:availability_rule, member: available, day_of_week: event.date.wday)

      result = described_class.new(event, role).candidates
      scores = result.map { |c| [c[:member].name, c[:score]] }.to_h
      expect(scores["가용"]).to be > scores["규칙없음"]
    end
  end
end
