class StatisticsPolicy < Struct.new(:user, :statistics)
  def index?
    user&.admin? || user&.operator?
  end
end
