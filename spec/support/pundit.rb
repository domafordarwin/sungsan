require "pundit/matchers"

RSpec.configure do |config|
  config.include Pundit::Matchers, type: :policy
end
