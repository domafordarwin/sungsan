class Photo < ApplicationRecord
  include Auditable

  belongs_to :photo_album
  belongs_to :uploader, class_name: "User"
  has_one_attached :image

  validates :image, presence: true

  scope :ordered, -> { order(:position, :created_at) }

  def uploaded_by?(user)
    uploader_id == user.id
  end
end
