class CreateActiveStoragePostgresqlTables < ActiveRecord::Migration[8.0]
  def change
    create_table :active_storage_postgresql_files do |t|
      t.oid :data
      t.string :key, null: false
      t.index :key, unique: true
    end
  end
end
