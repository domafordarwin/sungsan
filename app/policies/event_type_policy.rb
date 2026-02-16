class EventTypePolicy < ApplicationPolicy
  def index?
    operator_or_admin?
  end

  def show?
    operator_or_admin?
  end

  def create?
    admin?
  end

  def update?
    admin?
  end

  def destroy?
    admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end
end
