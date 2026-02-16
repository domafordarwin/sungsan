class SurveyPolicy < ApplicationPolicy
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

  class Scope < Scope
    def resolve
      scope.all
    end
  end
end
