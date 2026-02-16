RSpec.describe "Assignments", type: :request do
  let(:parish) { create(:parish) }
  let(:admin) { create(:user, :admin, parish: parish, password: "password123") }
  let(:operator) { create(:user, :operator, parish: parish, password: "password123") }
  let(:member_user) { create(:user, :member_role, parish: parish, password: "password123") }
  let!(:event_type) { create(:event_type, parish: parish, name: "주일미사") }
  let!(:role) { create(:role, parish: parish, name: "십자가봉사") }
  let!(:event) { create(:event, parish: parish, event_type: event_type, date: Date.current + 7.days, start_time: "09:00") }
  let!(:member) { create(:member, parish: parish, name: "김복사", active: true) }

  describe "as admin" do
    before { sign_in(admin) }

    it "POST creates assignment" do
      expect {
        post event_assignments_path(event), params: { assignment: { member_id: member.id, role_id: role.id } }
      }.to change(Assignment, :count).by(1)
      expect(Assignment.last.status).to eq("pending")
      expect(response).to redirect_to(event_path(event))
    end

    it "POST sets assigned_by to current user" do
      post event_assignments_path(event), params: { assignment: { member_id: member.id, role_id: role.id } }
      expect(Assignment.last.assigned_by).to eq(admin)
    end

    it "POST duplicate member+role+event is rejected" do
      create(:assignment, event: event, member: member, role: role)
      post event_assignments_path(event), params: { assignment: { member_id: member.id, role_id: role.id } }
      expect(response).to redirect_to(event_path(event))
      expect(flash[:alert]).to be_present
    end

    it "DELETE cancels assignment" do
      assignment = create(:assignment, event: event, member: member, role: role)
      delete event_assignment_path(event, assignment)
      expect(assignment.reload.status).to eq("canceled")
      expect(response).to redirect_to(event_path(event))
    end

    it "GET recommend returns candidates" do
      create(:event_role_requirement, event_type: event_type, role: role, required_count: 2)
      get recommend_event_assignments_path(event, role_id: role.id)
      expect(response).to have_http_status(:ok)
    end
  end

  describe "as operator" do
    before { sign_in(operator) }

    it "POST creates assignment" do
      expect {
        post event_assignments_path(event), params: { assignment: { member_id: member.id, role_id: role.id } }
      }.to change(Assignment, :count).by(1)
    end

    it "DELETE cancels assignment" do
      assignment = create(:assignment, event: event, member: member, role: role)
      delete event_assignment_path(event, assignment)
      expect(assignment.reload.status).to eq("canceled")
    end
  end

  describe "as member" do
    before { sign_in(member_user) }

    it "POST is forbidden" do
      post event_assignments_path(event), params: { assignment: { member_id: member.id, role_id: role.id } }
      expect(response).to redirect_to(root_path)
    end

    it "DELETE is forbidden" do
      assignment = create(:assignment, event: event, member: member, role: role)
      delete event_assignment_path(event, assignment)
      expect(response).to redirect_to(root_path)
    end
  end
end
