class AvailabilityRulesController < ApplicationController
  before_action :require_authentication
  before_action :set_member

  def create
    @rule = @member.availability_rules.build(availability_rule_params)
    if @rule.save
      redirect_to @member, notice: "가용성 규칙이 추가되었습니다."
    else
      redirect_to @member, alert: "저장에 실패했습니다: #{@rule.errors.full_messages.join(', ')}"
    end
  end

  def destroy
    @rule = @member.availability_rules.find(params[:id])
    @rule.destroy
    redirect_to @member, notice: "가용성 규칙이 삭제되었습니다."
  end

  private

  def set_member
    @member = Member.find(params[:member_id])
  end

  def availability_rule_params
    params.require(:availability_rule).permit(:day_of_week, :event_type_id, :available, :max_per_month, :notes)
  end
end
