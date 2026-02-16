# Auto-setup production database
# Runs inside Rails process, independent of docker-entrypoint
if Rails.env.production?
  Rails.application.config.after_initialize do
    begin
      conn = ActiveRecord::Base.connection

      unless conn.table_exists?(:users)
        Rails.logger.info "=== AUTO SETUP: Tables missing, loading schema ==="

        # Load schema.rb directly
        schema_file = Rails.root.join("db", "schema.rb")
        if schema_file.exist?
          load(schema_file)
          Rails.logger.info "=== AUTO SETUP: Schema loaded ==="
        else
          Rails.logger.error "=== AUTO SETUP: schema.rb not found! ==="
        end
      end

      if conn.table_exists?(:users) && User.unscoped.count == 0
        Rails.logger.info "=== AUTO SETUP: Seeding database ==="
        Rails.application.load_seed
        Rails.logger.info "=== AUTO SETUP: Done (#{User.unscoped.count} users) ==="
      end
    rescue => e
      Rails.logger.error "=== AUTO SETUP FAILED: #{e.class}: #{e.message} ==="
      Rails.logger.error e.backtrace&.first(5)&.join("\n")
    end
  end
end
