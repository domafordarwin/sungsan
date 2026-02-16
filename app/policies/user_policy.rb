class UserPolicy < ApplicationPolicy
  def index?
    admin?
  end

  def show?
    admin? || record == user
  end

  def create?
    admin?
  end

  def update?
    admin?
  end

  def destroy?
    admin? && record != user
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.admin?
        scope.all
      else
        scope.where(id: user.id)
      end
    end
  end
end
