class CreateActiveStoragePostgresqlTables < ActiveRecord::Migration[8.0]
  def change
    create_table :active_storage_db_files do |t|
      t.string :ref, null: false
      t.binary :data, null: false
      t.datetime :created_at, precision: 6
    end

    add_index :active_storage_db_files, :ref, unique: true
  end
end
