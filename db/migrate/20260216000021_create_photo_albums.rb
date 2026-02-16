class CreatePhotoAlbums < ActiveRecord::Migration[8.0]
  def change
    create_table :photo_albums do |t|
      t.references :parish, null: false, foreign_key: true
      t.references :author, null: false, foreign_key: { to_table: :users }
      t.string :title, null: false
      t.text :description
      t.date :event_date
      t.boolean :sample_data, default: false, null: false
      t.timestamps
    end

    add_index :photo_albums, [:parish_id, :created_at]
  end
end
