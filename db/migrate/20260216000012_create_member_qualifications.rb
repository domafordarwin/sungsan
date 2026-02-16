class CreateMemberQualifications < ActiveRecord::Migration[8.0]
  def change
    create_table :member_qualifications do |t|
      t.references :member, null: false, foreign_key: true
      t.references :qualification, null: false, foreign_key: true
      t.date :acquired_date, null: false
      t.date :expires_date

      t.timestamps
    end

    add_index :member_qualifications, [:member_id, :qualification_id], unique: true, name: "idx_member_qual_unique"
  end
end
