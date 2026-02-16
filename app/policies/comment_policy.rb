class CommentPolicy < ApplicationPolicy
  def create?
    user.present?
  end

  def destroy?
    admin? || record.authored_by?(user)
  end
end
