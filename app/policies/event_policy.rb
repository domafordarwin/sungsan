class EventPolicy < ApplicationPolicy
  def index?
    operator_or_admin?
  end

  def show?
    operator_or_admin?
  end

  def create?
    operator_or_admin?
  end

  def update?
    operator_or_admin?
  end

  def destroy?
    admin?
  end

  def bulk_create?
    admin?
  end

  def destroy_recurring?
    admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end
end
