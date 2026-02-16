namespace :db do
  desc "Remove stale schema_migrations entries where the table was never actually created"
  task fix_stale_migrations: :environment do
    checks = {
      "20260216000018" => "news_articles",
      "20260216000019" => "posts",
      "20260216000020" => "comments",
      "20260216000021" => "photo_albums",
      "20260216000022" => "photos",
      "20260216000023" => "active_storage_blobs"
    }

    conn = ActiveRecord::Base.connection
    checks.each do |version, table_name|
      next if conn.table_exists?(table_name)

      conn.execute("DELETE FROM schema_migrations WHERE version = '#{version}'")
      puts "Removed stale migration #{version} (#{table_name} missing)"
    end
  end
end
