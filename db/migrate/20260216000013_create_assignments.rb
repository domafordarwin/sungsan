class CreateAssignments < ActiveRecord::Migration[8.0]
  def change
    create_table :assignments do |t|
      t.references :event, null: false, foreign_key: true
      t.references :role, null: false, foreign_key: true
      t.references :member, null: false, foreign_key: true
      t.string :status, null: false, default: "pending"
      t.string :response_token
      t.datetime :response_token_expires_at
      t.datetime :responded_at
      t.text :decline_reason
      t.bigint :replaced_by_id
      t.bigint :assigned_by_id

      t.timestamps
    end

    add_index :assignments, [:event_id, :role_id, :member_id], unique: true, name: "idx_assignment_unique"
    add_index :assignments, :response_token, unique: true
    add_index :assignments, :status
    add_foreign_key :assignments, :members, column: :replaced_by_id
    add_foreign_key :assignments, :users, column: :assigned_by_id
  end
end
