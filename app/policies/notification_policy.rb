class NotificationPolicy < ApplicationPolicy
  def index?
    operator_or_admin?
  end

  def show?
    operator_or_admin?
  end

  def create?
    operator_or_admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end
end
