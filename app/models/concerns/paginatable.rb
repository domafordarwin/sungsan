module Paginatable
  extend ActiveSupport::Concern

  class_methods do
    def page(page_number)
      page_number = [page_number.to_i, 1].max
      offset((page_number - 1) * per_page_count)
    end

    def per(count)
      limit(count)
    end

    def per_page_count
      20
    end
  end
end
