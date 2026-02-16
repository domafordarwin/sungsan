# Ensure missing tables are created before eager_load introspects them.
# Rails initializers run BEFORE eager_load!, so migrations here
# will create tables before any model class tries to read column info.
if Rails.env.production?
  begin
    conn = ActiveRecord::Base.connection

    missing = %w[news_articles posts comments photo_albums photos active_storage_blobs].reject do |t|
      conn.table_exists?(t)
    end

    if missing.any?
      Rails.logger.info("[ensure_tables] Missing tables: #{missing.join(', ')}. Cleaning stale migrations and running pending...")

      # Remove stale schema_migrations entries so migrations re-run
      stale = {
        "news_articles"        => "20260216000018",
        "posts"                => "20260216000019",
        "comments"             => "20260216000020",
        "photo_albums"         => "20260216000021",
        "photos"               => "20260216000022",
        "active_storage_blobs" => "20260216000023"
      }

      missing.each do |table|
        version = stale[table]
        conn.execute("DELETE FROM schema_migrations WHERE version = '#{version}'") if version
      end

      # Run pending migrations (before eager_load, no model classes loaded yet)
      ActiveRecord::MigrationContext.new(Rails.root.join("db/migrate")).migrate
      Rails.logger.info("[ensure_tables] Migrations completed")
    end
  rescue => e
    Rails.logger.warn("[ensure_tables] Skipped: #{e.message}")
  end
end
