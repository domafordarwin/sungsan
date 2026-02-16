class CreateAttendanceRecords < ActiveRecord::Migration[8.0]
  def change
    create_table :attendance_records do |t|
      t.references :event, null: false, foreign_key: true
      t.references :member, null: false, foreign_key: true
      t.references :assignment, foreign_key: true
      t.string :status, null: false
      t.text :reason
      t.bigint :recorded_by_id

      t.timestamps
    end

    add_index :attendance_records, [:event_id, :member_id], unique: true, name: "idx_attendance_unique"
    add_foreign_key :attendance_records, :users, column: :recorded_by_id
  end
end
