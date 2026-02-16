require "rails_helper"

RSpec.describe "Members", type: :request do
  let(:parish) { create(:parish) }
  let(:admin) { create(:user, :admin, parish: parish, password: "password123") }
  let(:operator) { create(:user, :operator, parish: parish, password: "password123") }
  let(:member_user) { create(:user, :member_role, parish: parish, password: "password123") }

  let!(:active_member) { create(:member, parish: parish, name: "김요한", baptismal_name: "요한", district: "1구역") }
  let!(:inactive_member) { create(:member, :inactive, parish: parish, name: "박베드로", baptismal_name: "베드로", district: "2구역") }

  describe "as admin" do
    before { sign_in(admin) }

    describe "GET /members" do
      it "returns success" do
        get members_path
        expect(response).to have_http_status(:ok)
      end

      it "searches by name" do
        get members_path, params: { q: "김요한" }
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("김요한")
      end

      it "filters active members" do
        get members_path, params: { active: "true" }
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("김요한")
        expect(response.body).not_to include("박베드로")
      end

      it "filters inactive members" do
        get members_path, params: { active: "false" }
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("박베드로")
      end
    end

    describe "GET /members/:id" do
      it "shows member details" do
        get member_path(active_member)
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("김요한")
      end
    end

    describe "GET /members/new" do
      it "renders new form" do
        get new_member_path
        expect(response).to have_http_status(:ok)
      end
    end

    describe "POST /members" do
      it "creates a member" do
        expect {
          post members_path, params: {
            member: { name: "이마리아", baptismal_name: "마리아", district: "3구역" }
          }
        }.to change(Member, :count).by(1)
        expect(response).to redirect_to(member_path(Member.last))
      end

      it "rejects invalid member" do
        post members_path, params: { member: { name: "" } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    describe "PATCH /members/:id" do
      it "updates member" do
        patch member_path(active_member), params: { member: { name: "김요한 수정" } }
        expect(response).to redirect_to(member_path(active_member))
        expect(active_member.reload.name).to eq("김요한 수정")
      end
    end

    describe "PATCH /members/:id/toggle_active" do
      it "deactivates an active member" do
        patch toggle_active_member_path(active_member)
        expect(response).to redirect_to(member_path(active_member))
        expect(active_member.reload.active).to be false
      end

      it "activates an inactive member" do
        patch toggle_active_member_path(inactive_member)
        expect(response).to redirect_to(member_path(inactive_member))
        expect(inactive_member.reload.active).to be true
      end
    end
  end

  describe "as operator" do
    before { sign_in(operator) }

    it "GET /members returns success" do
      get members_path
      expect(response).to have_http_status(:ok)
    end

    it "GET /members/:id shows member" do
      get member_path(active_member)
      expect(response).to have_http_status(:ok)
    end

    it "PATCH /members/:id updates member" do
      patch member_path(active_member), params: { member: { district: "5구역" } }
      expect(response).to redirect_to(member_path(active_member))
    end

    it "POST /members is forbidden" do
      post members_path, params: { member: { name: "New" } }
      expect(response).to redirect_to(root_path)
    end

    it "PATCH /members/:id/toggle_active is forbidden" do
      patch toggle_active_member_path(active_member)
      expect(response).to redirect_to(root_path)
    end
  end

  describe "as member" do
    before { sign_in(member_user) }

    it "GET /members is forbidden" do
      get members_path
      expect(response).to redirect_to(root_path)
    end
  end
end
