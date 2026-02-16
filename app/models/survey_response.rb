class SurveyResponse < ApplicationRecord
  belongs_to :survey

  validates :respondent_name, presence: true
  validates :answers, presence: true

  before_create { self.submitted_at = Time.current }

  def answer_for(question_id)
    answers[question_id.to_s]
  end
end
