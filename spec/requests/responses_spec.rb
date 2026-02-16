RSpec.describe "Responses", type: :request do
  let(:parish) { create(:parish) }
  let(:event_type) { create(:event_type, parish: parish) }
  let(:role) { create(:role, parish: parish) }
  let(:event) { create(:event, parish: parish, event_type: event_type, date: Date.current + 7.days, start_time: "09:00") }
  let(:member) { create(:member, parish: parish, active: true, name: "김복사") }
  let(:assignment) do
    a = create(:assignment, event: event, role: role, member: member, status: "pending")
    a.generate_response_token!
    a
  end

  describe "GET /respond/:token" do
    it "shows assignment details" do
      get response_path(assignment.response_token)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("김복사")
      expect(response.body).to include(role.name)
    end

    it "returns 410 for expired token" do
      assignment.update!(response_token_expires_at: 1.hour.ago)
      get response_path(assignment.response_token)
      expect(response).to have_http_status(:gone)
    end

    it "returns 410 for already responded assignment" do
      assignment.accept!
      get response_path(assignment.response_token)
      expect(response).to have_http_status(:gone)
    end

    it "returns 404 for invalid token" do
      expect {
        get response_path("invalid_token_xxx")
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe "PATCH /respond/:token" do
    it "accepts assignment" do
      patch response_path(assignment.response_token), params: { response: "accept" }
      expect(assignment.reload.status).to eq("accepted")
      expect(response).to redirect_to(completed_response_path(assignment.response_token))
    end

    it "declines assignment with reason" do
      patch response_path(assignment.response_token), params: { response: "decline", decline_reason: "개인 사정" }
      expect(assignment.reload.status).to eq("declined")
      expect(assignment.decline_reason).to eq("개인 사정")
      expect(response).to redirect_to(completed_response_path(assignment.response_token))
    end

    it "returns 410 for expired token" do
      assignment.update!(response_token_expires_at: 1.hour.ago)
      patch response_path(assignment.response_token), params: { response: "accept" }
      expect(response).to have_http_status(:gone)
    end
  end

  describe "GET /respond/:token/completed" do
    it "shows completion page for accepted" do
      assignment.accept!
      get completed_response_path(assignment.response_token)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("수락")
    end

    it "shows completion page for declined" do
      assignment.decline!("사정")
      get completed_response_path(assignment.response_token)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("거절")
    end
  end
end
