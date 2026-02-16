class CreateNewsArticles < ActiveRecord::Migration[8.0]
  def change
    create_table :news_articles do |t|
      t.references :parish, null: false, foreign_key: true
      t.string :title, null: false
      t.text :summary
      t.string :source_name, null: false
      t.string :source_url, null: false
      t.string :external_id
      t.string :image_url
      t.datetime :published_at
      t.boolean :sample_data, default: false, null: false

      t.timestamps
    end

    add_index :news_articles, [:parish_id, :published_at]
    add_index :news_articles, :external_id, unique: true
    add_index :news_articles, :sample_data
  end
end
