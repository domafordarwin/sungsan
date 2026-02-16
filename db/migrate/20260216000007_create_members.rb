class CreateMembers < ActiveRecord::Migration[8.0]
  def change
    create_table :members do |t|
      t.references :parish, null: false, foreign_key: true
      t.references :user, foreign_key: true
      t.string :name, null: false
      t.string :baptismal_name
      t.string :phone
      t.string :email
      t.date :birth_date
      t.string :gender
      t.string :district
      t.string :group_name
      t.boolean :baptized, default: false
      t.boolean :confirmed, default: false
      t.boolean :active, default: true
      t.text :notes

      t.timestamps
    end

    add_index :members, :user_id, unique: true
    add_index :members, [:parish_id, :active]
  end
end
