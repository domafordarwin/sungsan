class MemberPolicy < ApplicationPolicy
  def index?
    operator_or_admin?
  end

  def show?
    operator_or_admin? || (record.user_id == user.id)
  end

  def create?
    admin?
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

  def bulk_destroy?
    admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.admin? || user.operator?
        scope.all
      else
        scope.where(user_id: user.id)
      end
    end
  end
end
