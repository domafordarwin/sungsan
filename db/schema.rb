# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2026_02_16_000023) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.string "name", null: false
    t.string "record_type", null: false
    t.bigint "record_id", null: false
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.string "key", null: false
    t.string "filename", null: false
    t.string "content_type"
    t.text "metadata"
    t.string "service_name", null: false
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.datetime "created_at", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "assignments", force: :cascade do |t|
    t.bigint "assigned_by_id"
    t.datetime "created_at", null: false
    t.text "decline_reason"
    t.bigint "event_id", null: false
    t.bigint "member_id", null: false
    t.bigint "replaced_by_id"
    t.datetime "responded_at"
    t.string "response_token"
    t.datetime "response_token_expires_at"
    t.bigint "role_id", null: false
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.index ["event_id", "role_id", "member_id"], name: "idx_assignment_unique", unique: true
    t.index ["event_id"], name: "index_assignments_on_event_id"
    t.index ["member_id"], name: "index_assignments_on_member_id"
    t.index ["response_token"], name: "index_assignments_on_response_token", unique: true
    t.index ["role_id"], name: "index_assignments_on_role_id"
    t.index ["status"], name: "index_assignments_on_status"
  end

  create_table "attendance_records", force: :cascade do |t|
    t.bigint "assignment_id"
    t.datetime "created_at", null: false
    t.bigint "event_id", null: false
    t.bigint "member_id", null: false
    t.text "reason"
    t.bigint "recorded_by_id"
    t.string "status", null: false
    t.datetime "updated_at", null: false
    t.index ["assignment_id"], name: "index_attendance_records_on_assignment_id"
    t.index ["event_id", "member_id"], name: "idx_attendance_unique", unique: true
    t.index ["event_id"], name: "index_attendance_records_on_event_id"
    t.index ["member_id"], name: "index_attendance_records_on_member_id"
  end

  create_table "audit_logs", force: :cascade do |t|
    t.string "action", null: false
    t.bigint "auditable_id", null: false
    t.string "auditable_type", null: false
    t.jsonb "changes_data"
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.bigint "parish_id"
    t.string "user_agent"
    t.bigint "user_id"
    t.index ["auditable_type", "auditable_id"], name: "index_audit_logs_on_auditable_type_and_auditable_id"
    t.index ["created_at"], name: "index_audit_logs_on_created_at"
    t.index ["user_id"], name: "index_audit_logs_on_user_id"
  end

  create_table "availability_rules", force: :cascade do |t|
    t.boolean "available", default: true
    t.datetime "created_at", null: false
    t.integer "day_of_week"
    t.bigint "event_type_id"
    t.integer "max_per_month"
    t.bigint "member_id", null: false
    t.text "notes"
    t.datetime "updated_at", null: false
    t.index ["event_type_id"], name: "index_availability_rules_on_event_type_id"
    t.index ["member_id"], name: "index_availability_rules_on_member_id"
  end

  create_table "blackout_periods", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "end_date", null: false
    t.bigint "member_id", null: false
    t.string "reason"
    t.date "start_date", null: false
    t.datetime "updated_at", null: false
    t.index ["member_id"], name: "index_blackout_periods_on_member_id"
  end

  create_table "comments", force: :cascade do |t|
    t.bigint "post_id", null: false
    t.bigint "author_id", null: false
    t.text "body", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_comments_on_author_id"
    t.index ["post_id", "created_at"], name: "index_comments_on_post_id_and_created_at"
    t.index ["post_id"], name: "index_comments_on_post_id"
  end

  create_table "event_role_requirements", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "event_type_id", null: false
    t.integer "required_count", default: 1, null: false
    t.bigint "role_id", null: false
    t.datetime "updated_at", null: false
    t.index ["event_type_id", "role_id"], name: "idx_event_role_req_unique", unique: true
    t.index ["event_type_id"], name: "index_event_role_requirements_on_event_type_id"
    t.index ["role_id"], name: "index_event_role_requirements_on_role_id"
  end

  create_table "event_types", force: :cascade do |t|
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.time "default_time"
    t.text "description"
    t.string "name", null: false
    t.bigint "parish_id", null: false
    t.boolean "sample_data", default: false, null: false
    t.datetime "updated_at", null: false
    t.index ["parish_id", "name"], name: "index_event_types_on_parish_id_and_name", unique: true
    t.index ["parish_id"], name: "index_event_types_on_parish_id"
    t.index ["sample_data"], name: "index_event_types_on_sample_data"
  end

  create_table "events", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.date "date", null: false
    t.time "end_time"
    t.bigint "event_type_id", null: false
    t.string "location"
    t.text "notes"
    t.bigint "parish_id", null: false
    t.string "recurring_group_id"
    t.boolean "sample_data", default: false, null: false
    t.time "start_time", null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.index ["event_type_id"], name: "index_events_on_event_type_id"
    t.index ["parish_id", "date"], name: "index_events_on_parish_id_and_date"
    t.index ["parish_id"], name: "index_events_on_parish_id"
    t.index ["recurring_group_id"], name: "index_events_on_recurring_group_id"
    t.index ["sample_data"], name: "index_events_on_sample_data"
  end

  create_table "member_qualifications", force: :cascade do |t|
    t.date "acquired_date", null: false
    t.datetime "created_at", null: false
    t.date "expires_date"
    t.bigint "member_id", null: false
    t.bigint "qualification_id", null: false
    t.datetime "updated_at", null: false
    t.index ["member_id", "qualification_id"], name: "idx_member_qual_unique", unique: true
    t.index ["member_id"], name: "index_member_qualifications_on_member_id"
    t.index ["qualification_id"], name: "index_member_qualifications_on_qualification_id"
  end

  create_table "members", force: :cascade do |t|
    t.boolean "active", default: true
    t.string "baptismal_name"
    t.boolean "baptized", default: false
    t.date "birth_date"
    t.boolean "confirmed", default: false
    t.datetime "created_at", null: false
    t.string "district"
    t.string "email"
    t.string "gender"
    t.string "group_name"
    t.string "name", null: false
    t.text "notes"
    t.bigint "parish_id", null: false
    t.string "phone"
    t.boolean "sample_data", default: false, null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["parish_id", "active"], name: "index_members_on_parish_id_and_active"
    t.index ["parish_id"], name: "index_members_on_parish_id"
    t.index ["sample_data"], name: "index_members_on_sample_data"
    t.index ["user_id"], name: "index_members_on_user_id", unique: true
  end

  create_table "news_articles", force: :cascade do |t|
    t.bigint "parish_id", null: false
    t.string "title", null: false
    t.text "summary"
    t.string "source_name", null: false
    t.string "source_url", null: false
    t.string "external_id"
    t.string "image_url"
    t.datetime "published_at"
    t.boolean "sample_data", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["external_id"], name: "index_news_articles_on_external_id", unique: true
    t.index ["parish_id", "published_at"], name: "index_news_articles_on_parish_id_and_published_at"
    t.index ["parish_id"], name: "index_news_articles_on_parish_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.text "body"
    t.string "channel", default: "email", null: false
    t.datetime "created_at", null: false
    t.string "notification_type", null: false
    t.bigint "parish_id", null: false
    t.datetime "read_at"
    t.bigint "recipient_id"
    t.bigint "related_id"
    t.string "related_type"
    t.bigint "sender_id"
    t.datetime "sent_at"
    t.string "status", default: "pending"
    t.string "subject"
    t.datetime "updated_at", null: false
    t.index ["parish_id"], name: "index_notifications_on_parish_id"
    t.index ["related_type", "related_id"], name: "index_notifications_on_related_type_and_related_id"
  end

  create_table "parishes", force: :cascade do |t|
    t.string "address"
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.string "phone"
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_parishes_on_name", unique: true
  end

  create_table "photo_albums", force: :cascade do |t|
    t.bigint "parish_id", null: false
    t.bigint "author_id", null: false
    t.string "title", null: false
    t.text "description"
    t.date "event_date"
    t.boolean "sample_data", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["parish_id", "created_at"], name: "index_photo_albums_on_parish_id_and_created_at"
    t.index ["parish_id"], name: "index_photo_albums_on_parish_id"
    t.index ["author_id"], name: "index_photo_albums_on_author_id"
  end

  create_table "photos", force: :cascade do |t|
    t.bigint "photo_album_id", null: false
    t.bigint "uploader_id", null: false
    t.string "caption"
    t.integer "position", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["photo_album_id", "position"], name: "index_photos_on_photo_album_id_and_position"
    t.index ["photo_album_id"], name: "index_photos_on_photo_album_id"
    t.index ["uploader_id"], name: "index_photos_on_uploader_id"
  end

  create_table "posts", force: :cascade do |t|
    t.bigint "parish_id", null: false
    t.bigint "author_id", null: false
    t.string "title", null: false
    t.text "body", null: false
    t.boolean "pinned", default: false
    t.integer "comments_count", default: 0
    t.boolean "sample_data", default: false, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["author_id"], name: "index_posts_on_author_id"
    t.index ["parish_id", "created_at"], name: "index_posts_on_parish_id_and_created_at"
    t.index ["parish_id"], name: "index_posts_on_parish_id"
  end

  create_table "qualifications", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.bigint "parish_id", null: false
    t.boolean "sample_data", default: false, null: false
    t.datetime "updated_at", null: false
    t.integer "validity_months"
    t.index ["parish_id", "name"], name: "index_qualifications_on_parish_id_and_name", unique: true
    t.index ["parish_id"], name: "index_qualifications_on_parish_id"
    t.index ["sample_data"], name: "index_qualifications_on_sample_data"
  end

  create_table "roles", force: :cascade do |t|
    t.boolean "active", default: true
    t.datetime "created_at", null: false
    t.text "description"
    t.integer "max_members"
    t.integer "min_age"
    t.string "name", null: false
    t.bigint "parish_id", null: false
    t.boolean "requires_baptism", default: false
    t.boolean "requires_confirmation", default: false
    t.boolean "sample_data", default: false, null: false
    t.integer "sort_order", default: 0
    t.datetime "updated_at", null: false
    t.index ["parish_id", "name"], name: "index_roles_on_parish_id_and_name", unique: true
    t.index ["parish_id"], name: "index_roles_on_parish_id"
    t.index ["sample_data"], name: "index_roles_on_sample_data"
  end

  create_table "sessions", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "ip_address"
    t.datetime "updated_at", null: false
    t.string "user_agent"
    t.bigint "user_id", null: false
    t.index ["user_id"], name: "index_sessions_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "email_address", null: false
    t.string "name", null: false
    t.bigint "parish_id", null: false
    t.string "password_digest", null: false
    t.string "role", default: "member", null: false
    t.boolean "sample_data", default: false, null: false
    t.datetime "updated_at", null: false
    t.index ["email_address"], name: "index_users_on_email_address", unique: true
    t.index ["parish_id"], name: "index_users_on_parish_id"
    t.index ["sample_data"], name: "index_users_on_sample_data"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "assignments", "events"
  add_foreign_key "assignments", "members"
  add_foreign_key "assignments", "members", column: "replaced_by_id"
  add_foreign_key "assignments", "roles"
  add_foreign_key "assignments", "users", column: "assigned_by_id"
  add_foreign_key "attendance_records", "assignments"
  add_foreign_key "attendance_records", "events"
  add_foreign_key "attendance_records", "members"
  add_foreign_key "attendance_records", "users", column: "recorded_by_id"
  add_foreign_key "audit_logs", "parishes"
  add_foreign_key "audit_logs", "users"
  add_foreign_key "availability_rules", "event_types"
  add_foreign_key "availability_rules", "members"
  add_foreign_key "blackout_periods", "members"
  add_foreign_key "comments", "posts"
  add_foreign_key "comments", "users", column: "author_id"
  add_foreign_key "event_role_requirements", "event_types"
  add_foreign_key "event_role_requirements", "roles"
  add_foreign_key "event_types", "parishes"
  add_foreign_key "events", "event_types"
  add_foreign_key "events", "parishes"
  add_foreign_key "member_qualifications", "members"
  add_foreign_key "member_qualifications", "qualifications"
  add_foreign_key "members", "parishes"
  add_foreign_key "members", "users"
  add_foreign_key "news_articles", "parishes"
  add_foreign_key "notifications", "members", column: "recipient_id"
  add_foreign_key "notifications", "parishes"
  add_foreign_key "notifications", "users", column: "sender_id"
  add_foreign_key "photo_albums", "parishes"
  add_foreign_key "photo_albums", "users", column: "author_id"
  add_foreign_key "photos", "photo_albums"
  add_foreign_key "photos", "users", column: "uploader_id"
  add_foreign_key "posts", "parishes"
  add_foreign_key "posts", "users", column: "author_id"
  add_foreign_key "qualifications", "parishes"
  add_foreign_key "roles", "parishes"
  add_foreign_key "sessions", "users"
  add_foreign_key "users", "parishes"
end
