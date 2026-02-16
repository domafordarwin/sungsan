class CreateEventTypes < ActiveRecord::Migration[8.0]
  def change
    create_table :event_types do |t|
      t.references :parish, null: false, foreign_key: true
      t.string :name, null: false
      t.text :description
      t.time :default_time
      t.boolean :active, default: true

      t.timestamps
    end

    add_index :event_types, [:parish_id, :name], unique: true
  end
end
