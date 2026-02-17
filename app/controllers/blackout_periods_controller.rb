class BlackoutPeriodsController < ApplicationController
  before_action :require_authentication
  before_action :set_member

  def create
    @period = @member.blackout_periods.build(blackout_period_params)
    if @period.save
      redirect_to @member, notice: "휴가/불가 기간이 등록되었습니다."
    else
      redirect_to @member, alert: "저장에 실패했습니다: #{@period.errors.full_messages.join(', ')}"
    end
  end

  def destroy
    @period = @member.blackout_periods.find(params[:id])
    @period.destroy
    redirect_to @member, notice: "휴가/불가 기간이 삭제되었습니다."
  end

  private

  def set_member
    @member = Member.find(params[:member_id])
  end

  def blackout_period_params
    params.require(:blackout_period).permit(:start_date, :end_date, :reason)
  end
end
