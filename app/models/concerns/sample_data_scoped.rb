module SampleDataScoped
  extend ActiveSupport::Concern

  included do
    scope :demo_data,  -> { where(sample_data: true) }
    scope :real_data,  -> { where(sample_data: false) }
  end
end
