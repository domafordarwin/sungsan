module Admin
  class EventTypesController < ApplicationController
    before_action :set_event_type, only: %i[show edit update toggle_active]

    def index
      @event_types = policy_scope(EventType).ordered
      authorize EventType
    end

    def show
      authorize @event_type
      @requirements = @event_type.event_role_requirements.includes(:role).order("roles.sort_order")
      @available_roles = Role.active.ordered.where.not(id: @requirements.select(:role_id))
    end

    def new
      @event_type = EventType.new(parish_id: Current.parish_id)
      authorize @event_type
    end

    def create
      @event_type = EventType.new(event_type_params)
      @event_type.parish_id = Current.parish_id
      authorize @event_type

      if @event_type.save
        redirect_to admin_event_type_path(@event_type), notice: "미사유형이 등록되었습니다."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      authorize @event_type
    end

    def update
      authorize @event_type
      if @event_type.update(event_type_params)
        redirect_to admin_event_type_path(@event_type), notice: "미사유형 정보가 수정되었습니다."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def toggle_active
      authorize @event_type, :destroy?
      @event_type.update!(active: !@event_type.active)
      status = @event_type.active? ? "활성화" : "비활성화"
      redirect_to admin_event_type_path(@event_type), notice: "미사유형이 #{status}되었습니다."
    end

    private

    def set_event_type
      @event_type = EventType.find(params[:id])
    end

    def event_type_params
      params.require(:event_type).permit(:name, :description, :default_time)
    end
  end
end
