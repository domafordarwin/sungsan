class PhotoAlbum < ApplicationRecord
  include ParishScoped
  include Auditable
  include Paginatable
  include SampleDataScoped

  belongs_to :author, class_name: "User"
  has_many :photos, dependent: :destroy

  validates :title, presence: true

  scope :recent, -> { order(event_date: :desc, created_at: :desc) }

  def cover_photo
    photos.order(:position).first
  end

  def authored_by?(user)
    author_id == user.id
  end
end
