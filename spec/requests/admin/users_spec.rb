require "rails_helper"

RSpec.describe "Admin::Users", type: :request do
  let(:parish) { create(:parish) }
  let(:admin) { create(:user, :admin, parish: parish, password: "password123") }
  let(:operator) { create(:user, :operator, parish: parish, password: "password123") }
  let(:member_user) { create(:user, :member_role, parish: parish, password: "password123") }

  describe "as admin" do
    before { sign_in(admin) }

    describe "GET /admin/users" do
      it "returns success" do
        get admin_users_path
        expect(response).to have_http_status(:ok)
      end
    end

    describe "GET /admin/users/:id" do
      it "shows user details" do
        target = create(:user, parish: parish)
        get admin_user_path(target)
        expect(response).to have_http_status(:ok)
      end
    end

    describe "GET /admin/users/new" do
      it "renders new user form" do
        get new_admin_user_path
        expect(response).to have_http_status(:ok)
      end
    end

    describe "POST /admin/users" do
      it "creates a user" do
        expect {
          post admin_users_path, params: {
            user: {
              name: "New User",
              email_address: "new@test.com",
              role: "member",
              password: "password123",
              password_confirmation: "password123"
            }
          }
        }.to change(User, :count).by(1)
        expect(response).to redirect_to(admin_user_path(User.last))
      end
    end

    describe "PATCH /admin/users/:id" do
      it "updates user info" do
        target = create(:user, parish: parish)
        patch admin_user_path(target), params: { user: { name: "Updated Name" } }
        expect(response).to redirect_to(admin_user_path(target))
        expect(target.reload.name).to eq("Updated Name")
      end
    end

    describe "DELETE /admin/users/:id" do
      it "deletes a user" do
        target = create(:user, parish: parish)
        expect {
          delete admin_user_path(target)
        }.to change(User, :count).by(-1)
        expect(response).to redirect_to(admin_users_path)
      end

      it "cannot delete self" do
        delete admin_user_path(admin)
        expect(response).to redirect_to(root_path)
        expect(User.exists?(admin.id)).to be true
      end
    end
  end

  describe "as operator" do
    before { sign_in(operator) }

    it "GET /admin/users is forbidden" do
      get admin_users_path
      expect(response).to redirect_to(root_path)
    end
  end

  describe "as member" do
    before { sign_in(member_user) }

    it "GET /admin/users is forbidden" do
      get admin_users_path
      expect(response).to redirect_to(root_path)
    end
  end
end
