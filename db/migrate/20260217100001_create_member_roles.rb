class CreateMemberRoles < ActiveRecord::Migration[8.0]
  def change
    create_table :member_roles do |t|
      t.references :member, null: false, foreign_key: true
      t.references :role, null: false, foreign_key: true
      t.timestamps
    end
    add_index :member_roles, [:member_id, :role_id], unique: true
  end
end
