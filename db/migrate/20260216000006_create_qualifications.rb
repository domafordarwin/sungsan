class CreateQualifications < ActiveRecord::Migration[8.0]
  def change
    create_table :qualifications do |t|
      t.references :parish, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.integer :validity_months

      t.timestamps
    end

    add_index :qualifications, [:parish_id, :name], unique: true
  end
end
