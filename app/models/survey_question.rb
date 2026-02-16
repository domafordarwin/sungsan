class SurveyQuestion < ApplicationRecord
  belongs_to :survey

  validates :question_text, presence: true
  validates :question_type, inclusion: { in: %w[text radio checkbox select number] }
  validates :position, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  def options_list
    options.is_a?(Array) ? options : []
  end
end
