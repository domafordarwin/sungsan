RSpec.describe "Assignment Substitute", type: :request do
  let(:parish) { create(:parish) }
  let(:admin) { create(:user, :admin, parish: parish, password: "password123") }
  let(:member_user) { create(:user, :member_role, parish: parish, password: "password123") }
  let!(:event_type) { create(:event_type, parish: parish) }
  let!(:role) { create(:role, parish: parish) }
  let!(:event) { create(:event, parish: parish, event_type: event_type, date: Date.current + 7.days, start_time: "09:00") }
  let!(:original_member) { create(:member, parish: parish, active: true, name: "원래봉사자") }
  let!(:substitute_member) { create(:member, parish: parish, active: true, name: "대타봉사자") }

  describe "as admin" do
    before { sign_in(admin) }

    let!(:declined_assignment) do
      a = create(:assignment, event: event, role: role, member: original_member, status: "declined")
      a.generate_response_token!
      a
    end

    it "POST substitute creates new assignment and updates original" do
      expect {
        post substitute_event_assignment_path(event, declined_assignment), params: { member_id: substitute_member.id }
      }.to change(Assignment, :count).by(1)

      expect(declined_assignment.reload.status).to eq("replaced")
      expect(declined_assignment.replaced_by_id).to eq(substitute_member.id)

      new_assignment = Assignment.last
      expect(new_assignment.member).to eq(substitute_member)
      expect(new_assignment.role).to eq(role)
      expect(new_assignment.status).to eq("pending")
      expect(new_assignment.response_token).to be_present
    end

    it "POST substitute redirects to event" do
      post substitute_event_assignment_path(event, declined_assignment), params: { member_id: substitute_member.id }
      expect(response).to redirect_to(event_path(event))
    end
  end

  describe "as member" do
    before { sign_in(member_user) }

    it "POST substitute is forbidden" do
      declined = create(:assignment, event: event, role: role, member: original_member, status: "declined")
      post substitute_event_assignment_path(event, declined), params: { member_id: substitute_member.id }
      expect(response).to redirect_to(root_path)
    end
  end
end
