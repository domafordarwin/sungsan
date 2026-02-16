require "rails_helper"

RSpec.describe "Sessions", type: :request do
  let(:parish) { create(:parish) }
  let(:user) { create(:user, parish: parish, password: "password123") }

  describe "GET /session/new" do
    it "renders login page" do
      get new_session_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /session" do
    it "logs in with valid credentials" do
      post session_path, params: { email_address: user.email_address, password: "password123" }
      expect(response).to redirect_to(root_path)
      follow_redirect!
      expect(response.body).to include(user.name)
    end

    it "rejects invalid credentials" do
      post session_path, params: { email_address: user.email_address, password: "wrong" }
      expect(response).to redirect_to(new_session_path)
    end

    it "rejects non-existent email" do
      post session_path, params: { email_address: "nobody@example.com", password: "password123" }
      expect(response).to redirect_to(new_session_path)
    end

    it "creates a session record" do
      expect {
        post session_path, params: { email_address: user.email_address, password: "password123" }
      }.to change(Session, :count).by(1)
    end

    it "creates a login audit log" do
      expect {
        post session_path, params: { email_address: user.email_address, password: "password123" }
      }.to change(AuditLog, :count).by(1)
      expect(AuditLog.last.action).to eq("login")
    end
  end

  describe "DELETE /session" do
    before { sign_in(user) }

    it "logs out the user" do
      delete session_path
      expect(response).to redirect_to(new_session_path)
    end

    it "destroys the session record" do
      expect {
        delete session_path
      }.to change(Session, :count).by(-1)
    end

    it "creates a logout audit log" do
      expect {
        delete session_path
      }.to change { AuditLog.where(action: "logout").count }.by(1)
    end
  end

  describe "authentication redirect" do
    it "redirects unauthenticated users to login" do
      get root_path
      expect(response).to redirect_to(new_session_path)
    end
  end
end
