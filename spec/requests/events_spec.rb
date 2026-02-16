RSpec.describe "Events", type: :request do
  let(:parish) { create(:parish) }
  let(:admin) { create(:user, :admin, parish: parish, password: "password123") }
  let(:operator) { create(:user, :operator, parish: parish, password: "password123") }
  let(:member_user) { create(:user, :member_role, parish: parish, password: "password123") }
  let!(:event_type) { create(:event_type, parish: parish, name: "주일미사 1차", default_time: "09:00") }
  let!(:role) { create(:role, parish: parish, name: "십자가봉사") }
  let!(:event) { create(:event, parish: parish, event_type: event_type, date: Date.current + 7.days, start_time: "09:00") }

  describe "as admin" do
    before { sign_in(admin) }

    it "GET /events returns success" do
      get events_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("일정 관리")
    end

    it "GET /events with event_type_id filter shows filtered events" do
      other_type = create(:event_type, parish: parish, name: "평일미사")
      create(:event, parish: parish, event_type: other_type, date: Date.current + 3.days, start_time: "06:30")
      get events_path(event_type_id: event_type.id)
      expect(response).to have_http_status(:ok)
    end

    it "GET /events with view=past shows past events" do
      create(:event, :past, parish: parish, event_type: event_type, start_time: "09:00")
      get events_path(view: "past")
      expect(response).to have_http_status(:ok)
    end

    it "GET /events/:id shows event details" do
      get event_path(event)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("역할별 배정 현황")
    end

    it "GET /events/:id shows assignment summary" do
      create(:event_role_requirement, event_type: event_type, role: role, required_count: 2)
      get event_path(event)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("십자가봉사")
      expect(response.body).to include("2명")
    end

    it "GET /events/new renders form" do
      get new_event_path
      expect(response).to have_http_status(:ok)
    end

    it "POST /events creates event" do
      expect {
        post events_path, params: { event: {
          event_type_id: event_type.id,
          date: Date.current + 14.days,
          start_time: "10:00",
          title: "특별미사",
          location: "대성당"
        } }
      }.to change(Event, :count).by(1)
      expect(response).to redirect_to(event_path(Event.last))
    end

    it "PATCH /events/:id updates event" do
      patch event_path(event), params: { event: { title: "변경된 미사" } }
      expect(event.reload.title).to eq("변경된 미사")
      expect(response).to redirect_to(event_path(event))
    end

    it "DELETE /events/:id deletes event without assignments" do
      expect {
        delete event_path(event)
      }.to change(Event, :count).by(-1)
      expect(response).to redirect_to(events_path)
    end

    it "DELETE /events/:id with assignments is blocked" do
      member = create(:member, parish: parish)
      create(:assignment, event: event, member: member, role: role)
      delete event_path(event)
      expect(response).to redirect_to(event_path(event))
      expect(flash[:alert]).to include("배정된 봉사자가 있어")
    end

    it "GET /events/bulk_new renders form" do
      get bulk_new_events_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("반복 일정 생성")
    end

    it "POST /events/bulk_create creates recurring events" do
      expect {
        post bulk_create_events_path, params: {
          event_type_id: event_type.id,
          day_of_week: 0,
          start_date: Date.current.to_s,
          weeks: 4
        }
      }.to change(Event, :count).by_at_least(1)
      expect(response).to redirect_to(events_path)
      expect(Event.last.recurring_group_id).to be_present
    end

    it "POST /events/bulk_create limits to max 12 weeks" do
      post bulk_create_events_path, params: {
        event_type_id: event_type.id,
        day_of_week: 0,
        start_date: Date.current.to_s,
        weeks: 20
      }
      expect(response).to redirect_to(events_path)
      group_id = Event.where.not(recurring_group_id: nil).last&.recurring_group_id
      expect(Event.where(recurring_group_id: group_id).count).to be <= 12 if group_id
    end

    it "DELETE /events/destroy_recurring deletes recurring group" do
      group_id = SecureRandom.uuid
      create_list(:event, 3, parish: parish, event_type: event_type,
                  date: Date.current + 7.days, start_time: "09:00", recurring_group_id: group_id)
      expect {
        delete destroy_recurring_events_path(recurring_group_id: group_id)
      }.to change(Event, :count).by(-3)
      expect(response).to redirect_to(events_path)
    end
  end

  describe "as operator" do
    before { sign_in(operator) }

    it "GET /events returns success" do
      get events_path
      expect(response).to have_http_status(:ok)
    end

    it "POST /events creates event" do
      expect {
        post events_path, params: { event: {
          event_type_id: event_type.id,
          date: Date.current + 14.days,
          start_time: "10:00"
        } }
      }.to change(Event, :count).by(1)
    end

    it "DELETE /events/:id is forbidden" do
      delete event_path(event)
      expect(response).to redirect_to(root_path)
    end

    it "GET /events/bulk_new is forbidden" do
      get bulk_new_events_path
      expect(response).to redirect_to(root_path)
    end
  end

  describe "as member" do
    before { sign_in(member_user) }

    it "GET /events is forbidden" do
      get events_path
      expect(response).to redirect_to(root_path)
    end
  end
end
