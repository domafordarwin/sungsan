class AssignmentPolicy < ApplicationPolicy
  def create?
    operator_or_admin?
  end

  def destroy?
    operator_or_admin?
  end

  def recommend?
    operator_or_admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end
end
