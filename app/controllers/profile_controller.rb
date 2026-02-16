class ProfileController < ApplicationController
  def show
    @member = Current.user.member
    if @member
      authorize @member, :show?
    else
      skip_authorization
      redirect_to root_path, alert: "연결된 봉사자 정보가 없습니다."
    end
  end
end
