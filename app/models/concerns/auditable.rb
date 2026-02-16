module Auditable
  extend ActiveSupport::Concern

  included do
    after_create { log_audit("create") }
    after_update { log_audit("update") }
    after_destroy { log_audit("destroy") }
  end

  private

  def log_audit(action)
    AuditLog.create!(
      parish_id: try(:parish_id) || Current.parish_id,
      user_id: Current.user&.id,
      action: action,
      auditable: self,
      changes_data: action == "create" ? attributes : saved_changes.except("updated_at"),
      ip_address: Current.ip_address,
      user_agent: Current.user_agent
    )
  rescue StandardError => e
    Rails.logger.error("Audit log failed: #{e.message}")
  end
end
