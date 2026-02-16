class CreateBlackoutPeriods < ActiveRecord::Migration[8.0]
  def change
    create_table :blackout_periods do |t|
      t.references :member, null: false, foreign_key: true
      t.date :start_date, null: false
      t.date :end_date, null: false
      t.string :reason

      t.timestamps
    end
  end
end
