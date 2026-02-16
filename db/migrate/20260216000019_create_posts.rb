class CreatePosts < ActiveRecord::Migration[8.0]
  def change
    create_table :posts do |t|
      t.references :parish, null: false, foreign_key: true
      t.references :author, null: false, foreign_key: { to_table: :users }
      t.string :title, null: false
      t.text :body, null: false
      t.boolean :pinned, default: false, null: false
      t.integer :comments_count, default: 0, null: false
      t.boolean :sample_data, default: false, null: false

      t.timestamps
    end

    add_index :posts, [:parish_id, :created_at]
    add_index :posts, :sample_data
  end
end
