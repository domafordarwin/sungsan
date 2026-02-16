module ParishScoped
  extend ActiveSupport::Concern

  included do
    belongs_to :parish
    validates :parish_id, presence: true

    default_scope -> { where(parish_id: Current.parish_id) if Current.parish_id }
  end

  class_methods do
    def unscoped_by_parish
      unscope(where: :parish_id)
    end
  end
end
