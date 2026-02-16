class Notification < ApplicationRecord
  include ParishScoped
  include Paginatable

  TYPES = %w[assignment reminder announcement].freeze
  CHANNELS = %w[email sms push].freeze
  STATUSES = %w[pending sent failed read].freeze

  belongs_to :recipient, class_name: "Member", optional: true
  belongs_to :sender, class_name: "User", optional: true
  belongs_to :related, polymorphic: true, optional: true

  validates :notification_type, presence: true, inclusion: { in: TYPES }
  validates :channel, presence: true, inclusion: { in: CHANNELS }
  validates :status, inclusion: { in: STATUSES }
end
