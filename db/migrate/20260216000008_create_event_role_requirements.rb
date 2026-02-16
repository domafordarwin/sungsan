class CreateEventRoleRequirements < ActiveRecord::Migration[8.0]
  def change
    create_table :event_role_requirements do |t|
      t.references :event_type, null: false, foreign_key: true
      t.references :role, null: false, foreign_key: true
      t.integer :required_count, null: false, default: 1

      t.timestamps
    end

    add_index :event_role_requirements, [:event_type_id, :role_id], unique: true, name: "idx_event_role_req_unique"
  end
end
