RSpec.describe "Admin::Roles", type: :request do
  let(:parish) { create(:parish) }
  let(:admin) { create(:user, :admin, parish: parish, password: "password123") }
  let(:operator) { create(:user, :operator, parish: parish, password: "password123") }
  let(:member_user) { create(:user, :member_role, parish: parish, password: "password123") }
  let!(:role) { create(:role, parish: parish, name: "십자가봉사") }

  describe "as admin" do
    before { sign_in(admin) }

    it "GET /admin/roles returns success" do
      get admin_roles_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("십자가봉사")
    end

    it "GET /admin/roles/:id shows role" do
      get admin_role_path(role)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(role.name)
    end

    it "GET /admin/roles/new renders form" do
      get new_admin_role_path
      expect(response).to have_http_status(:ok)
    end

    it "POST /admin/roles creates role" do
      expect {
        post admin_roles_path, params: { role: { name: "초봉사", sort_order: 1 } }
      }.to change(Role, :count).by(1)
      expect(response).to redirect_to(admin_role_path(Role.last))
    end

    it "PATCH /admin/roles/:id updates role" do
      patch admin_role_path(role), params: { role: { name: "향봉사" } }
      expect(role.reload.name).to eq("향봉사")
    end

    it "PATCH /admin/roles/:id/toggle_active toggles status" do
      expect(role.active).to be true
      patch toggle_active_admin_role_path(role)
      expect(role.reload.active).to be false
    end

    it "shows event types that require this role" do
      event_type = create(:event_type, parish: parish, name: "주일미사")
      create(:event_role_requirement, event_type: event_type, role: role, required_count: 2)
      get admin_role_path(role)
      expect(response.body).to include("주일미사")
      expect(response.body).to include("2명")
    end
  end

  describe "as operator" do
    before { sign_in(operator) }

    it "GET /admin/roles returns success" do
      get admin_roles_path
      expect(response).to have_http_status(:ok)
    end

    it "GET /admin/roles/:id shows role" do
      get admin_role_path(role)
      expect(response).to have_http_status(:ok)
    end

    it "POST /admin/roles is forbidden" do
      post admin_roles_path, params: { role: { name: "새역할", sort_order: 0 } }
      expect(response).to redirect_to(root_path)
    end
  end

  describe "as member" do
    before { sign_in(member_user) }

    it "GET /admin/roles is forbidden" do
      get admin_roles_path
      expect(response).to redirect_to(root_path)
    end
  end
end
