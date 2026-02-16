class NewsArticlePolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
  end

  def refresh?
    admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end
end
