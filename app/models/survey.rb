class Survey < ApplicationRecord
  include ParishScoped
  include Auditable
  include Paginatable

  belongs_to :event, optional: true
  belongs_to :created_by, class_name: "User"
  has_many :survey_questions, -> { order(:position) }, dependent: :destroy
  has_many :survey_responses, dependent: :destroy

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9\-]+\z/ }
  validates :status, inclusion: { in: %w[draft active closed] }

  before_validation :generate_slug, on: :create

  scope :active, -> { where(status: "active") }
  scope :draft, -> { where(status: "draft") }
  scope :closed, -> { where(status: "closed") }
  scope :ordered, -> { order(created_at: :desc) }

  accepts_nested_attributes_for :survey_questions, allow_destroy: true, reject_if: :all_blank

  def active?
    status == "active" && (starts_at.nil? || starts_at <= Time.current) && (ends_at.nil? || ends_at >= Time.current)
  end

  def response_count
    survey_responses.count
  end

  def public_url
    "/l/#{slug}"
  end

  private

  def generate_slug
    return if slug.present?

    base = title.to_s.parameterize.presence || SecureRandom.hex(4)
    self.slug = "#{base}-#{SecureRandom.hex(3)}"
  end
end
