class Post < ApplicationRecord
  include ParishScoped
  include Auditable
  include Paginatable
  include SampleDataScoped

  belongs_to :author, class_name: "User"
  has_many :comments, dependent: :destroy

  validates :title, presence: true
  validates :body, presence: true

  scope :pinned_first, -> { order(pinned: :desc, created_at: :desc) }
  scope :recent, -> { order(created_at: :desc) }

  def authored_by?(user)
    author_id == user.id
  end
end
