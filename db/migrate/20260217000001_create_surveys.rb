class CreateSurveys < ActiveRecord::Migration[8.0]
  def change
    create_table :surveys do |t|
      t.references :parish, null: false, foreign_key: true
      t.references :event, null: true, foreign_key: true
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.string :title, null: false
      t.text :description
      t.string :slug, null: false
      t.string :status, null: false, default: "draft"
      t.string :banner_image_url
      t.datetime :starts_at
      t.datetime :ends_at
      t.timestamps
    end

    add_index :surveys, :slug, unique: true
    add_index :surveys, :status

    create_table :survey_questions do |t|
      t.references :survey, null: false, foreign_key: true
      t.string :question_text, null: false
      t.string :question_type, null: false, default: "text"
      t.jsonb :options, default: []
      t.integer :position, null: false, default: 0
      t.boolean :required, null: false, default: false
      t.timestamps
    end

    add_index :survey_questions, [:survey_id, :position]

    create_table :survey_responses do |t|
      t.references :survey, null: false, foreign_key: true
      t.string :respondent_name
      t.string :respondent_phone
      t.string :respondent_email
      t.jsonb :answers, default: {}
      t.datetime :submitted_at
      t.timestamps
    end

    add_index :survey_responses, :submitted_at
  end
end
