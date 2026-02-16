RSpec.describe "Admin::EventTypes", type: :request do
  let(:parish) { create(:parish) }
  let(:admin) { create(:user, :admin, parish: parish, password: "password123") }
  let(:operator) { create(:user, :operator, parish: parish, password: "password123") }
  let(:member_user) { create(:user, :member_role, parish: parish, password: "password123") }
  let!(:event_type) { create(:event_type, parish: parish, name: "주일미사 1차") }
  let!(:role) { create(:role, parish: parish, name: "십자가봉사") }

  describe "as admin" do
    before { sign_in(admin) }

    it "GET /admin/event_types returns success" do
      get admin_event_types_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("주일미사 1차")
    end

    it "GET /admin/event_types/:id shows event type" do
      get admin_event_type_path(event_type)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(event_type.name)
    end

    it "GET /admin/event_types/new renders form" do
      get new_admin_event_type_path
      expect(response).to have_http_status(:ok)
    end

    it "POST /admin/event_types creates event type" do
      expect {
        post admin_event_types_path, params: { event_type: { name: "평일미사", default_time: "06:30" } }
      }.to change(EventType, :count).by(1)
      expect(response).to redirect_to(admin_event_type_path(EventType.last))
    end

    it "PATCH /admin/event_types/:id updates event type" do
      patch admin_event_type_path(event_type), params: { event_type: { name: "주일미사 2차" } }
      expect(event_type.reload.name).to eq("주일미사 2차")
    end

    it "PATCH /admin/event_types/:id/toggle_active toggles status" do
      expect(event_type.active).to be true
      patch toggle_active_admin_event_type_path(event_type)
      expect(event_type.reload.active).to be false
    end

    # EventRoleRequirement tests
    it "POST creates event role requirement" do
      expect {
        post admin_event_type_event_role_requirements_path(event_type),
            params: { event_role_requirement: { role_id: role.id, required_count: 2 } }
      }.to change(EventRoleRequirement, :count).by(1)
      expect(response).to redirect_to(admin_event_type_path(event_type))
    end

    it "PATCH updates event role requirement count" do
      req = create(:event_role_requirement, event_type: event_type, role: role, required_count: 1)
      patch admin_event_type_event_role_requirement_path(event_type, req),
          params: { event_role_requirement: { required_count: 3 } }
      expect(req.reload.required_count).to eq(3)
    end

    it "DELETE removes event role requirement" do
      req = create(:event_role_requirement, event_type: event_type, role: role)
      expect {
        delete admin_event_type_event_role_requirement_path(event_type, req)
      }.to change(EventRoleRequirement, :count).by(-1)
    end

    it "shows total required count on index" do
      create(:event_role_requirement, event_type: event_type, role: role, required_count: 3)
      get admin_event_types_path
      expect(response.body).to include("3명")
    end
  end

  describe "as operator" do
    before { sign_in(operator) }

    it "GET /admin/event_types returns success" do
      get admin_event_types_path
      expect(response).to have_http_status(:ok)
    end

    it "POST /admin/event_types is forbidden" do
      post admin_event_types_path, params: { event_type: { name: "새유형" } }
      expect(response).to redirect_to(root_path)
    end

    it "POST event_role_requirement is forbidden" do
      post admin_event_type_event_role_requirements_path(event_type),
          params: { event_role_requirement: { role_id: role.id, required_count: 1 } }
      expect(response).to redirect_to(root_path)
    end
  end

  describe "as member" do
    before { sign_in(member_user) }

    it "GET /admin/event_types is forbidden" do
      get admin_event_types_path
      expect(response).to redirect_to(root_path)
    end
  end
end
