class CreateEvents < ActiveRecord::Migration[8.0]
  def change
    create_table :events do |t|
      t.references :parish, null: false, foreign_key: true
      t.references :event_type, null: false, foreign_key: true
      t.string :title
      t.date :date, null: false
      t.time :start_time, null: false
      t.time :end_time
      t.string :location
      t.text :notes
      t.string :recurring_group_id

      t.timestamps
    end

    add_index :events, [:parish_id, :date]
    add_index :events, :recurring_group_id
  end
end
