module SampleDataScoped
  extend ActiveSupport::Concern

  included do
    scope :sample,     -> { where(sample_data: true) }
    scope :non_sample, -> { where(sample_data: false) }
  end
end
