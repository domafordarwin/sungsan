module Admin
  class UsersController < ApplicationController
    before_action :set_user, only: %i[show edit update destroy]

    def index
      @users = policy_scope(User)
      authorize User
    end

    def show
      authorize @user
    end

    def new
      @user = User.new(parish_id: Current.parish_id)
      authorize @user
    end

    def create
      @user = User.new(user_params)
      @user.parish_id = Current.parish_id
      authorize @user

      if @user.save
        redirect_to admin_user_path(@user), notice: "사용자가 생성되었습니다."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      authorize @user
    end

    def update
      authorize @user
      if @user.update(user_params)
        redirect_to admin_user_path(@user), notice: "사용자 정보가 수정되었습니다."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      authorize @user
      @user.destroy
      redirect_to admin_users_path, notice: "사용자가 삭제되었습니다."
    end

    private

    def set_user
      @user = User.find(params[:id])
    end

    def user_params
      params.require(:user).permit(:email_address, :name, :role, :password, :password_confirmation)
    end
  end
end
