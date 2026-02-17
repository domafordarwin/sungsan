class AddPerformanceIndexes < ActiveRecord::Migration[8.0]
  def change
    # Assignments: composite index for common query patterns
    unless index_exists?(:assignments, [:event_id, :role_id, :status])
      add_index :assignments, [:event_id, :role_id, :status], name: "idx_assignments_event_role_status"
    end
    unless index_exists?(:assignments, [:member_id, :status])
      add_index :assignments, [:member_id, :status], name: "idx_assignments_member_status"
    end

    # Attendance records: composite index for event+status lookups
    unless index_exists?(:attendance_records, [:event_id, :status])
      add_index :attendance_records, [:event_id, :status], name: "idx_attendance_event_status"
    end

    # Events: composite index for parish+date queries (status column does not exist on events)
    unless index_exists?(:events, [:parish_id, :date])
      add_index :events, [:parish_id, :date], name: "idx_events_parish_date"
    end

    # Audit logs: composite index for parish-scoped time-ordered queries
    unless index_exists?(:audit_logs, [:parish_id, :created_at])
      add_index :audit_logs, [:parish_id, :created_at], name: "idx_audit_logs_parish_created"
    end

    # Notifications: composite index for parish-scoped time-ordered queries
    unless index_exists?(:notifications, [:parish_id, :created_at])
      add_index :notifications, [:parish_id, :created_at], name: "idx_notifications_parish_created"
    end

    # Members: composite index for active member lookup per parish
    unless index_exists?(:members, [:parish_id, :active])
      add_index :members, [:parish_id, :active], name: "idx_members_parish_active"
    end
  end
end
