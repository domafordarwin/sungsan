class Current < ActiveSupport::CurrentAttributes
  attribute :user
  attribute :parish_id
  attribute :ip_address
  attribute :user_agent

  def parish
    Parish.find(parish_id) if parish_id
  end
end
