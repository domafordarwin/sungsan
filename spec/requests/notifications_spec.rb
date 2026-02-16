RSpec.describe "Notifications", type: :request do
  let(:parish) { create(:parish) }
  let(:admin) { create(:user, :admin, parish: parish, password: "password123") }
  let(:member_user) { create(:user, :member_role, parish: parish, password: "password123") }

  describe "as admin" do
    before { sign_in(admin) }

    it "GET index shows notifications" do
      get notifications_path
      expect(response).to have_http_status(:ok)
    end

    it "GET new shows form" do
      get new_notification_path
      expect(response).to have_http_status(:ok)
    end

    it "POST create sends announcement" do
      expect {
        post notifications_path, params: {
          notification: { subject: "테스트 공지", body: "공지 내용", channel: "email" }
        }
      }.to change(Notification, :count).by(1)
      expect(Notification.last.notification_type).to eq("announcement")
      expect(Notification.last.sender).to eq(admin)
      expect(response).to redirect_to(notifications_path)
    end

    it "GET show displays notification" do
      notification = Notification.create!(
        parish: parish, notification_type: "announcement",
        channel: "email", subject: "테스트", body: "내용",
        status: "sent", sender: admin
      )
      get notification_path(notification)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("테스트")
    end
  end

  describe "as member" do
    before { sign_in(member_user) }

    it "GET index is forbidden" do
      get notifications_path
      expect(response).to redirect_to(root_path)
    end

    it "POST create is forbidden" do
      post notifications_path, params: {
        notification: { subject: "해킹", body: "시도", channel: "email" }
      }
      expect(response).to redirect_to(root_path)
    end
  end
end
