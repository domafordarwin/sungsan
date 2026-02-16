class CreateAuditLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :audit_logs do |t|
      t.bigint :parish_id
      t.bigint :user_id
      t.string :action, null: false
      t.string :auditable_type, null: false
      t.bigint :auditable_id, null: false
      t.jsonb :changes_data
      t.string :ip_address
      t.string :user_agent

      t.datetime :created_at, null: false
    end

    add_index :audit_logs, [:auditable_type, :auditable_id]
    add_index :audit_logs, :user_id
    add_index :audit_logs, :created_at
    add_foreign_key :audit_logs, :parishes
    add_foreign_key :audit_logs, :users
  end
end
