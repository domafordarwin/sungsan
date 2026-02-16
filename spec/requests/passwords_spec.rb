require "rails_helper"

RSpec.describe "Passwords", type: :request do
  let(:parish) { create(:parish) }
  let(:user) { create(:user, parish: parish, password: "password123") }

  before { sign_in(user) }

  describe "GET /password/edit" do
    it "renders password change form" do
      get edit_password_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "PATCH /password" do
    it "changes password with valid params" do
      patch password_path, params: { user: { password: "newpassword123", password_confirmation: "newpassword123" } }
      expect(response).to redirect_to(root_path)
    end

    it "creates a password_change audit log" do
      expect {
        patch password_path, params: { user: { password: "newpassword123", password_confirmation: "newpassword123" } }
      }.to change { AuditLog.where(action: "password_change").count }.by(1)
    end

    it "rejects mismatched confirmation" do
      patch password_path, params: { user: { password: "newpassword123", password_confirmation: "different" } }
      expect(response).to have_http_status(:unprocessable_entity)
    end
  end
end
