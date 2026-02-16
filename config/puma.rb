# Puma configuration for AltarServe Manager

max_threads_count = ENV.fetch("RAILS_MAX_THREADS") { 5 }
min_threads_count = ENV.fetch("RAILS_MIN_THREADS") { max_threads_count }
threads min_threads_count, max_threads_count

# Railway/Docker: single process mode to minimize memory usage
# Set WEB_CONCURRENCY=2 if you need workers on larger instances
if ENV["RAILS_ENV"] == "production"
  worker_count = Integer(ENV.fetch("WEB_CONCURRENCY") { 0 })
  workers worker_count if worker_count > 0
end

worker_timeout 3600 if ENV.fetch("RAILS_ENV", "development") == "development"

# Bind to 0.0.0.0 so Railway/Docker can route traffic
app_port = ENV.fetch("PORT") { 3000 }
bind "tcp://0.0.0.0:#{app_port}"

environment ENV.fetch("RAILS_ENV") { "development" }

pidfile ENV.fetch("PIDFILE") { "tmp/pids/server.pid" }

# Allow puma to be restarted by `bin/rails restart` command.
plugin :tmp_restart

# Log when Puma starts
after_booted do
  puts "=== Puma booted on port #{app_port} ==="
end
