class NewsArticle < ApplicationRecord
  include ParishScoped
  include Auditable
  include SampleDataScoped
  include Paginatable

  SOURCE_NAMES = %w[naver catholic_news diocese].freeze

  validates :title, presence: true
  validates :source_name, presence: true, inclusion: { in: SOURCE_NAMES }
  validates :source_url, presence: true
  validates :external_id, uniqueness: true, allow_nil: true

  scope :recent, -> { order(published_at: :desc) }
  scope :by_source, ->(source) { where(source_name: source) }

  def source_label
    case source_name
    when "naver" then "네이버"
    when "catholic_news" then "가톨릭뉴스"
    when "diocese" then "교구"
    else source_name
    end
  end

  def source_badge_class
    case source_name
    when "naver" then "badge-moss"
    when "catholic_news" then "badge-ocean"
    when "diocese" then "badge-sunrise"
    else "badge-basalt"
    end
  end
end
