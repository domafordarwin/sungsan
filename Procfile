release: SKIP_EAGER_LOAD=1 bundle exec rails db:fix_stale_migrations db:prepare db:seed
web: bundle exec puma -C config/puma.rb
