require "rails_helper"

RSpec.describe "Dashboard", type: :request do
  let(:parish) { create(:parish) }
  let(:user) { create(:user, parish: parish, password: "password123") }

  describe "GET /" do
    context "when authenticated" do
      before { sign_in(user) }

      it "returns success" do
        get root_path
        expect(response).to have_http_status(:ok)
      end

      it "displays user name" do
        get root_path
        expect(response.body).to include(user.name)
      end
    end

    context "when not authenticated" do
      it "redirects to login" do
        get root_path
        expect(response).to redirect_to(new_session_path)
      end
    end
  end
end
