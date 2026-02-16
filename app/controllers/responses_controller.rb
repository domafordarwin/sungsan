class ResponsesController < ApplicationController
  allow_unauthenticated_access
  layout "response"

  before_action :find_assignment_by_token, only: [:show, :update]

  def show
  end

  def update
    case params[:response]
    when "accept"
      @assignment.accept!
    when "decline"
      @assignment.decline!(params[:decline_reason])
    else
      redirect_to response_path(@assignment.response_token), alert: "잘못된 요청입니다."
      return
    end

    redirect_to completed_response_path(@assignment.response_token)
  end

  def completed
    @assignment = Assignment.find_by!(response_token: params[:token])
  end

  private

  def find_assignment_by_token
    @assignment = Assignment.find_by!(response_token: params[:token])
    render :expired, status: :gone unless @assignment.respondable?
  end

  def skip_authorization?
    true
  end
end
