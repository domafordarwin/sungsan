class CreateRoles < ActiveRecord::Migration[8.0]
  def change
    create_table :roles do |t|
      t.references :parish, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.boolean :requires_baptism, default: false
      t.boolean :requires_confirmation, default: false
      t.integer :min_age
      t.integer :max_members
      t.integer :sort_order, default: 0
      t.boolean :active, default: true

      t.timestamps
    end

    add_index :roles, [:parish_id, :name], unique: true
  end
end
