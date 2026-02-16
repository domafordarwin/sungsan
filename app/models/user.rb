class User < ApplicationRecord
  include ParishScoped
  include SampleDataScoped

  has_secure_password
  has_many :sessions, dependent: :destroy
  has_one :member, dependent: :nullify

  validates :email_address, presence: true, uniqueness: true,
    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true
  validates :role, presence: true, inclusion: { in: %w[admin operator member] }

  normalizes :email_address, with: ->(e) { e.strip.downcase }

  def admin?
    role == "admin"
  end

  def operator?
    role == "operator"
  end

  def member_role?
    role == "member"
  end
end
