module Admin
  class RolesController < ApplicationController
    before_action :set_role, only: %i[show edit update toggle_active]

    def index
      @roles = policy_scope(Role).ordered
      authorize Role
    end

    def show
      authorize @role
      @event_types = @role.event_role_requirements.includes(:event_type)
    end

    def new
      @role = Role.new(parish_id: Current.parish_id, sort_order: next_sort_order)
      authorize @role
    end

    def create
      @role = Role.new(role_params)
      @role.parish_id = Current.parish_id
      authorize @role

      if @role.save
        redirect_to admin_role_path(@role), notice: "역할이 등록되었습니다."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      authorize @role
    end

    def update
      authorize @role
      if @role.update(role_params)
        redirect_to admin_role_path(@role), notice: "역할 정보가 수정되었습니다."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def toggle_active
      authorize @role, :destroy?
      @role.update!(active: !@role.active)
      status = @role.active? ? "활성화" : "비활성화"
      redirect_to admin_role_path(@role), notice: "역할이 #{status}되었습니다."
    end

    private

    def set_role
      @role = Role.find(params[:id])
    end

    def role_params
      params.require(:role).permit(
        :name, :description, :requires_baptism, :requires_confirmation,
        :min_age, :max_members, :sort_order
      )
    end

    def next_sort_order
      (Role.maximum(:sort_order) || -1) + 1
    end
  end
end
