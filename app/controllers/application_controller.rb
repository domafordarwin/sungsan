class ApplicationController < ActionController::Base
  include Authentication
  include Pundit::Authorization

  before_action :set_current_attributes
  after_action :verify_authorized, except: :index, unless: :skip_authorization?
  after_action :verify_policy_scoped, only: :index, unless: :skip_authorization?

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  rescue_from StandardError, with: :handle_server_error

  private

  def pundit_user
    Current.user
  end

  def set_current_attributes
    if Current.session
      Current.user = Current.session.user
      Current.parish_id = Current.user.parish_id
      Current.ip_address = request.remote_ip
      Current.user_agent = request.user_agent
    end
  end

  def user_not_authorized
    redirect_back fallback_location: root_path, alert: "접근 권한이 없습니다."
  end

  def skip_authorization?
    is_a?(SessionsController) || is_a?(DashboardController) || is_a?(StatisticsController)
  end

  def handle_server_error(exception)
    Rails.logger.error("SERVER ERROR: #{exception.class}: #{exception.message}")
    Rails.logger.error(exception.backtrace&.first(15)&.join("\n"))
    render plain: "Error: #{exception.class} - #{exception.message}", status: :internal_server_error
  end
end
