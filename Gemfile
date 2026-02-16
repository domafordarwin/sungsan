source "https://rubygems.org"

gem "rails", "~> 8.0"
gem "pg", "~> 1.5"
gem "puma", ">= 5"
gem "propshaft"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "tailwindcss-rails"
gem "solid_queue"
gem "solid_cache"
gem "solid_cable"
gem "thruster", require: false
gem "pundit"
gem "bcrypt", "~> 3.1"
gem "bootsnap", require: false

group :development, :test do
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"
  gem "rspec-rails", "~> 7.0"
  gem "factory_bot_rails"
  gem "faker"
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
end

group :test do
  gem "shoulda-matchers"
  gem "capybara"
  gem "selenium-webdriver"
  gem "simplecov", require: false
  gem "database_cleaner-active_record"
  gem "pundit-matchers"
end

group :development do
  gem "web-console"
end
