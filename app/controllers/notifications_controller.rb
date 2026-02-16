class NotificationsController < ApplicationController
  def index
    authorize Notification
    @notifications = policy_scope(Notification).order(created_at: :desc).page(params[:page]).per(20)
  end

  def show
    @notification = Notification.find(params[:id])
    authorize @notification
  end

  def new
    @notification = Notification.new
    authorize @notification
  end

  def create
    @notification = Notification.new(notification_params)
    @notification.parish_id = Current.parish_id
    @notification.sender = Current.user
    @notification.notification_type = "announcement"
    @notification.status = "sent"
    @notification.sent_at = Time.current
    authorize @notification

    if @notification.save
      redirect_to notifications_path, notice: "공지가 발송되었습니다."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  def notification_params
    params.require(:notification).permit(:subject, :body, :channel)
  end
end
