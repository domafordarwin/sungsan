class SurveysController < ApplicationController
  before_action :set_survey, only: %i[show edit update destroy results]

  def index
    @surveys = policy_scope(Survey).ordered.page(params[:page]).per(20)
    authorize Survey
  end

  def show
    authorize @survey
  end

  def new
    @survey = Survey.new
    @survey.survey_questions.build
    authorize @survey
  end

  def create
    @survey = Survey.new(survey_params)
    @survey.parish_id = Current.parish_id
    @survey.created_by = Current.user
    authorize @survey

    if @survey.save
      redirect_to survey_path(@survey), notice: "설문이 생성되었습니다."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @survey
  end

  def update
    authorize @survey
    if @survey.update(survey_params)
      redirect_to survey_path(@survey), notice: "설문이 수정되었습니다."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @survey
    @survey.destroy
    redirect_to surveys_path, notice: "설문이 삭제되었습니다."
  end

  def results
    authorize @survey, :show?
    @responses = @survey.survey_responses.order(submitted_at: :desc)
  end

  private

  def set_survey
    @survey = Survey.find(params[:id])
  end

  def survey_params
    params.require(:survey).permit(
      :title, :description, :event_id, :status, :banner_image_url,
      :starts_at, :ends_at, :slug,
      survey_questions_attributes: %i[id question_text question_type required position _destroy] + [options: []]
    )
  end
end
