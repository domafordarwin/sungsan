class CreateNotifications < ActiveRecord::Migration[8.0]
  def change
    create_table :notifications do |t|
      t.references :parish, null: false, foreign_key: true
      t.bigint :recipient_id
      t.bigint :sender_id
      t.string :notification_type, null: false
      t.string :channel, null: false, default: "email"
      t.string :subject
      t.text :body
      t.string :status, default: "pending"
      t.datetime :sent_at
      t.datetime :read_at
      t.string :related_type
      t.bigint :related_id

      t.timestamps
    end

    add_foreign_key :notifications, :members, column: :recipient_id
    add_foreign_key :notifications, :users, column: :sender_id
    add_index :notifications, [:related_type, :related_id]
  end
end
