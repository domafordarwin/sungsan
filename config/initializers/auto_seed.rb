# Auto-seed production database if empty
# Uses find_or_create_by in seeds.rb, so safe to run multiple times
if Rails.env.production?
  Rails.application.config.after_initialize do
    begin
      if ActiveRecord::Base.connection.table_exists?(:users) && User.unscoped.count == 0
        Rails.logger.info "=== AUTO SEED: No users found, seeding database ==="
        Rails.application.load_seed
        Rails.logger.info "=== AUTO SEED: Complete (#{User.unscoped.count} users) ==="
      end
    rescue => e
      Rails.logger.error "=== AUTO SEED FAILED: #{e.message} ==="
    end
  end
end
