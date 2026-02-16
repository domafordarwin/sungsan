module ParishScoped
  extend ActiveSupport::Concern

  included do
    belongs_to :parish
    validates :parish_id, presence: true

    default_scope lambda {
      if Current.parish_id
        where(parish_id: Current.parish_id)
      end
    rescue ActiveRecord::StatementInvalid, PG::UndefinedTable
      # Table may not exist yet during migrations — skip scope gracefully
      nil
    }
  end

  class_methods do
    def unscoped_by_parish
      unscope(where: :parish_id)
    end
  end
end
