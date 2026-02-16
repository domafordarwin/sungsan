class PhotoAlbumPolicy < ApplicationPolicy
  def index?
    true
  end

  def show?
    true
  end

  def create?
    operator_or_admin?
  end

  def update?
    admin? || record.authored_by?(user)
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
