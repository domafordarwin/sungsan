RSpec.describe "AttendanceRecords", type: :request do
  let(:parish) { create(:parish) }
  let(:admin) { create(:user, :admin, parish: parish, password: "password123") }
  let(:member_user) { create(:user, :member_role, parish: parish, password: "password123") }
  let!(:event_type) { create(:event_type, parish: parish) }
  let!(:role) { create(:role, parish: parish) }
  let!(:event) { create(:event, parish: parish, event_type: event_type, date: Date.current - 1.day, start_time: "09:00") }
  let!(:member) { create(:member, parish: parish, active: true, name: "김복사") }
  let!(:assignment) { create(:assignment, :accepted, event: event, role: role, member: member) }

  describe "as admin" do
    before { sign_in(admin) }

    it "GET edit shows attendance form" do
      get edit_event_attendance_path(event)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("김복사")
    end

    it "PATCH update creates attendance records" do
      patch event_attendance_path(event), params: {
        attendance: {
          member.id.to_s => { status: "present", assignment_id: assignment.id, reason: "" }
        }
      }
      expect(response).to redirect_to(event_path(event))
      expect(AttendanceRecord.count).to eq(1)
      expect(AttendanceRecord.last.status).to eq("present")
      expect(AttendanceRecord.last.recorded_by).to eq(admin)
    end

    it "PATCH update updates existing records" do
      create(:attendance_record, event: event, member: member, assignment: assignment,
             status: "present", recorded_by: admin)
      patch event_attendance_path(event), params: {
        attendance: {
          member.id.to_s => { status: "absent", assignment_id: assignment.id, reason: "개인 사정" }
        }
      }
      expect(AttendanceRecord.last.status).to eq("absent")
      expect(AttendanceRecord.last.reason).to eq("개인 사정")
    end

    it "PATCH update skips blank status" do
      patch event_attendance_path(event), params: {
        attendance: {
          member.id.to_s => { status: "", assignment_id: assignment.id }
        }
      }
      expect(AttendanceRecord.count).to eq(0)
    end
  end

  describe "as member" do
    before { sign_in(member_user) }

    it "GET edit is forbidden" do
      get edit_event_attendance_path(event)
      expect(response).to redirect_to(root_path)
    end

    it "PATCH update is forbidden" do
      patch event_attendance_path(event), params: {
        attendance: { member.id.to_s => { status: "present" } }
      }
      expect(response).to redirect_to(root_path)
    end
  end
end
