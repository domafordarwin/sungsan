module Admin
  class EventRoleRequirementsController < ApplicationController
    before_action :set_event_type
    before_action :set_requirement, only: %i[update destroy]

    def create
      @requirement = @event_type.event_role_requirements.build(requirement_params)
      authorize @requirement, :create?

      if @requirement.save
        redirect_to admin_event_type_path(@event_type), notice: "역할이 추가되었습니다."
      else
        redirect_to admin_event_type_path(@event_type), alert: "역할 추가에 실패했습니다."
      end
    end

    def update
      authorize @requirement
      if @requirement.update(requirement_params)
        redirect_to admin_event_type_path(@event_type), notice: "필요인원이 수정되었습니다."
      else
        redirect_to admin_event_type_path(@event_type), alert: "수정에 실패했습니다."
      end
    end

    def destroy
      authorize @requirement
      @requirement.destroy
      redirect_to admin_event_type_path(@event_type), notice: "역할이 제거되었습니다."
    end

    private

    def set_event_type
      @event_type = EventType.find(params[:event_type_id])
    end

    def set_requirement
      @requirement = @event_type.event_role_requirements.find(params[:id])
    end

    def requirement_params
      params.require(:event_role_requirement).permit(:role_id, :required_count)
    end
  end
end
