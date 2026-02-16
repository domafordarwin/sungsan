class AddSampleDataToTables < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :sample_data, :boolean, default: false, null: false
    add_column :members, :sample_data, :boolean, default: false, null: false
    add_column :events, :sample_data, :boolean, default: false, null: false
    add_column :roles, :sample_data, :boolean, default: false, null: false
    add_column :event_types, :sample_data, :boolean, default: false, null: false
    add_column :qualifications, :sample_data, :boolean, default: false, null: false

    add_index :users, :sample_data
    add_index :members, :sample_data
    add_index :events, :sample_data
    add_index :roles, :sample_data
    add_index :event_types, :sample_data
    add_index :qualifications, :sample_data
  end
end
