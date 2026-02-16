require_relative "boot"

require "rails/all"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Sungsan
  class Application < Rails::Application
    config.load_defaults 8.0

    # Don't generate system test files.
    config.generators.system_tests = nil

    # Use RSpec instead of Minitest
    config.generators do |g|
      g.test_framework :rspec
      g.fixture_replacement :factory_bot, dir: "spec/factories"
    end

    # Set default locale to Korean
    config.i18n.default_locale = :ko
    config.i18n.available_locales = [:ko, :en]

    # Time zone
    config.time_zone = "Seoul"

    # Autoload lib
    config.autoload_lib(ignore: %w[assets tasks])
  end
end
