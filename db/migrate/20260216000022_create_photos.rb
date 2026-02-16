class CreatePhotos < ActiveRecord::Migration[8.0]
  def change
    create_table :photos do |t|
      t.references :photo_album, null: false, foreign_key: true
      t.references :uploader, null: false, foreign_key: { to_table: :users }
      t.string :caption
      t.integer :position, default: 0
      t.timestamps
    end

    add_index :photos, [:photo_album_id, :position]
  end
end
