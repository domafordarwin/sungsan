require "rails_helper"

RSpec.describe "Profile", type: :request do
  let(:parish) { create(:parish) }
  let(:member_user) { create(:user, :member_role, parish: parish, password: "password123") }
  let!(:member_record) { create(:member, parish: parish, user: member_user) }

  before { sign_in(member_user) }

  describe "GET /profile" do
    it "shows own profile" do
      get profile_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(member_record.name)
    end

    it "redirects when no member linked" do
      member_record.update_columns(user_id: nil)
      get profile_path
      expect(response).to redirect_to(root_path)
    end
  end
end
