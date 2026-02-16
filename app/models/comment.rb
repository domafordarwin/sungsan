class Comment < ApplicationRecord
  include Auditable

  belongs_to :post, counter_cache: true
  belongs_to :author, class_name: "User"

  validates :body, presence: true

  scope :recent, -> { order(created_at: :asc) }

  def authored_by?(user)
    author_id == user.id
  end
end
