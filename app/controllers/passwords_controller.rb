class PasswordsController < ApplicationController
  def edit
    authorize Current.user, :show?
  end

  def update
    authorize Current.user, :show?
    if Current.user.update(password_params)
      log_password_change
      redirect_to root_path, notice: "비밀번호가 변경되었습니다."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def password_params
    params.require(:user).permit(:password, :password_confirmation)
  end

  def log_password_change
    AuditLog.create!(
      parish_id: Current.parish_id,
      user_id: Current.user.id,
      action: "password_change",
      auditable: Current.user,
      changes_data: {},
      ip_address: request.remote_ip,
      user_agent: request.user_agent
    )
  rescue StandardError => e
    Rails.logger.error("Password change audit log failed: #{e.message}")
  end
end
