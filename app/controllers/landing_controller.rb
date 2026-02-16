class LandingController < ApplicationController
  allow_unauthenticated_access
  layout "landing"

  def show
    @survey = Survey.unscoped.includes(:survey_questions, :event).find_by!(slug: params[:slug])

    unless @survey.active?
      render :closed
      return
    end
  end

  def submit
    @survey = Survey.unscoped.includes(:survey_questions).find_by!(slug: params[:slug])

    unless @survey.active?
      render :closed
      return
    end

    @response = @survey.survey_responses.build(response_params)

    if @response.save
      redirect_to landing_complete_path(@survey.slug)
    else
      render :show, status: :unprocessable_entity
    end
  end

  def complete
    @survey = Survey.unscoped.find_by!(slug: params[:slug])
  end

  private

  def skip_authorization?
    true
  end

  def response_params
    params.require(:survey_response).permit(:respondent_name, :respondent_phone, :respondent_email, answers: {})
  end
end
