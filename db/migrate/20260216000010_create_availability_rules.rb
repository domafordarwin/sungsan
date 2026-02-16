class CreateAvailabilityRules < ActiveRecord::Migration[8.0]
  def change
    create_table :availability_rules do |t|
      t.references :member, null: false, foreign_key: true
      t.integer :day_of_week
      t.references :event_type, foreign_key: true
      t.boolean :available, default: true
      t.integer :max_per_month
      t.text :notes

      t.timestamps
    end
  end
end
