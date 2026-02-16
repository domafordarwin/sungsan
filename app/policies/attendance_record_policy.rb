class AttendanceRecordPolicy < ApplicationPolicy
  def edit?
    operator_or_admin?
  end

  def update?
    operator_or_admin?
  end
end
