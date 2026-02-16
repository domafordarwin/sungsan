class SessionsController < ApplicationController
  allow_unauthenticated_access only: %i[new create]
  # rate_limit to: 10, within: 3.minutes, only: :create, with: -> {
  #   redirect_to new_session_path, alert: "잠시 후 다시 시도해주세요."
  # }

  def new
  end

  def create
    user = User.authenticate_by(email_address: params[:email_address], password: params[:password])
    if user
      start_new_session_for(user)
      log_auth_event("login", user)
      redirect_to after_authentication_url, notice: "로그인되었습니다."
    else
      redirect_to new_session_path, alert: "이메일 또는 비밀번호가 올바르지 않습니다."
    end
  rescue => e
    Rails.logger.error("LOGIN ERROR: #{e.class}: #{e.message}")
    Rails.logger.error(e.backtrace&.first(10)&.join("\n"))
    redirect_to new_session_path, alert: "로그인 처리 중 오류가 발생했습니다: #{e.class}"
  end

  def destroy
    log_auth_event("logout", Current.user)
    terminate_session
    redirect_to new_session_path, notice: "로그아웃되었습니다."
  end

  private

  def log_auth_event(action, user)
    AuditLog.create!(
      parish_id: user.parish_id,
      user_id: user.id,
      action: action,
      auditable: user,
      changes_data: { ip_address: request.remote_ip },
      ip_address: request.remote_ip,
      user_agent: request.user_agent
    )
  rescue StandardError => e
    Rails.logger.error("Auth audit log failed: #{e.message}")
  end
end
