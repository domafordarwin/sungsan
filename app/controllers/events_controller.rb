class EventsController < ApplicationController
  before_action :set_event, only: %i[show edit update destroy]

  def index
    @events = apply_filters(policy_scope(Event))
    authorize Event
    @event_types = EventType.active.ordered
  end

  def show
    authorize @event
    @assignment_summary = @event.assignment_summary
  end

  def new
    @event = Event.new(parish_id: Current.parish_id, date: params[:date])
    authorize @event
    @event_types = EventType.active.ordered
  end

  def create
    @event = Event.new(event_params)
    @event.parish_id = Current.parish_id
    authorize @event

    if @event.save
      redirect_to event_path(@event), notice: "일정이 등록되었습니다."
    else
      @event_types = EventType.active.ordered
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @event
    @event_types = EventType.active.ordered
  end

  def update
    authorize @event
    if @event.update(event_params)
      redirect_to event_path(@event), notice: "일정이 수정되었습니다."
    else
      @event_types = EventType.active.ordered
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @event
    if @event.has_assignments?
      redirect_to event_path(@event), alert: "배정된 봉사자가 있어 삭제할 수 없습니다."
    else
      @event.destroy
      redirect_to events_path, notice: "일정이 삭제되었습니다."
    end
  end

  def bulk_new
    authorize Event, :bulk_create?
    @event_types = EventType.active.ordered
  end

  def bulk_create
    authorize Event, :bulk_create?
    result = generate_recurring_events
    if result[:created] > 0
      redirect_to events_path, notice: "#{result[:created]}개의 일정이 생성되었습니다."
    else
      @event_types = EventType.active.ordered
      flash.now[:alert] = result[:error] || "일정을 생성할 수 없습니다."
      render :bulk_new, status: :unprocessable_entity
    end
  end

  def destroy_recurring
    authorize Event, :destroy_recurring?
    group_id = params[:recurring_group_id]
    events = Event.where(recurring_group_id: group_id)
    deletable = events.reject(&:has_assignments?)
    count = deletable.count
    deletable.each(&:destroy)
    redirect_to events_path, notice: "#{count}개의 반복 일정이 삭제되었습니다."
  end

  private

  def set_event
    @event = Event.find(params[:id])
  end

  def event_params
    params.require(:event).permit(:event_type_id, :title, :date, :start_time, :end_time, :location, :notes)
  end

  def apply_filters(scope)
    scope = scope.by_event_type(params[:event_type_id]) if params[:event_type_id].present?
    scope = if params[:from].present? && params[:to].present?
              scope.in_date_range(params[:from], params[:to])
            elsif params[:view] == "past"
              scope.past
            else
              scope.upcoming
            end
    scope.includes(:event_type).page(params[:page])
  end

  def generate_recurring_events
    event_type = EventType.find(params[:event_type_id])
    day_of_week = params[:day_of_week].to_i
    weeks = [params[:weeks].to_i, 12].min
    start_date = Date.parse(params[:start_date])
    group_id = SecureRandom.uuid

    created = 0
    events = []

    weeks.times do |i|
      date = start_date + (i * 7).days
      date += (day_of_week - date.wday) % 7
      next if date < start_date

      events << Event.new(
        parish_id: Current.parish_id,
        event_type: event_type,
        date: date,
        start_time: event_type.default_time || "09:00",
        recurring_group_id: group_id
      )
    end

    Event.transaction do
      events.each do |event|
        event.save!
        created += 1
      end
    end

    { created: created, group_id: group_id }
  rescue ActiveRecord::RecordInvalid => e
    { created: 0, error: e.message }
  rescue Date::Error
    { created: 0, error: "날짜 형식이 올바르지 않습니다." }
  end
end
