# F05: Event/Schedule Management Design

> **Summary**: 미사/행사 일정 CRUD, 반복 일정 자동 생성, 필터/검색
>
> **Feature**: F05-events
> **Version**: 1.0
> **Date**: 2026-02-16
> **Status**: Draft
> **Plan Reference**: `docs/01-plan/features/F05-events.plan.md`

---

## 1. Model Updates

### 1.1 Event Model (수정)

기존 모델에 추가 scope과 Paginatable concern을 적용합니다.

```ruby
class Event < ApplicationRecord
  include ParishScoped
  include Auditable
  include Paginatable

  belongs_to :event_type
  has_many :assignments, dependent: :destroy
  has_many :attendance_records, dependent: :destroy

  validates :date, presence: true
  validates :start_time, presence: true

  scope :upcoming, -> { where("date >= ?", Date.current).order(:date, :start_time) }
  scope :past, -> { where("date < ?", Date.current).order(date: :desc) }
  scope :on_date, ->(date) { where(date: date) }
  scope :this_week, -> { where(date: Date.current.beginning_of_week..Date.current.end_of_week) }
  scope :this_month, -> { where(date: Date.current.beginning_of_month..Date.current.end_of_month) }
  scope :by_event_type, ->(event_type_id) { where(event_type_id: event_type_id) }
  scope :in_date_range, ->(from, to) { where(date: from..to) }
  scope :ordered, -> { order(:date, :start_time) }

  def display_name
    title.presence || "#{event_type.name} (#{date.strftime('%m/%d')})"
  end

  def has_assignments?
    assignments.exists?
  end

  def assignment_summary
    event_type.event_role_requirements.includes(:role).map do |req|
      assigned = assignments.where(role_id: req.role_id).count
      { role: req.role, required: req.required_count, assigned: assigned }
    end
  end
end
```

**변경사항:**
- `include Paginatable` 추가
- `scope :by_event_type` 추가 (미사유형 필터)
- `scope :in_date_range` 추가 (날짜 범위 필터)
- `scope :ordered` 추가 (기본 정렬)
- `has_assignments?` 메서드 추가 (삭제 가능 여부 확인)
- `assignment_summary` 메서드 추가 (배정 현황 요약)

---

## 2. Policy

### 2.1 EventPolicy

```ruby
class EventPolicy < ApplicationPolicy
  def index?
    operator_or_admin?
  end

  def show?
    operator_or_admin?
  end

  def create?
    operator_or_admin?
  end

  def update?
    operator_or_admin?
  end

  def destroy?
    admin?
  end

  def bulk_create?
    admin?
  end

  def destroy_recurring?
    admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end
end
```

**권한 규칙:**
- `index?`, `show?`, `create?`, `update?`: admin + operator
- `destroy?`, `bulk_create?`, `destroy_recurring?`: admin only

---

## 3. Controller

### 3.1 EventsController

**위치**: `app/controllers/events_controller.rb` (top-level, admin namespace 아님)

EventType/Role과 달리 Events는 operator도 자주 사용하므로 top-level로 배치합니다.

```ruby
class EventsController < ApplicationController
  before_action :set_event, only: %i[show edit update destroy]

  # GET /events
  def index
    @events = apply_filters(policy_scope(Event))
    authorize Event
    @event_types = EventType.active.ordered
  end

  # GET /events/:id
  def show
    authorize @event
    @assignment_summary = @event.assignment_summary
  end

  # GET /events/new
  def new
    @event = Event.new(parish_id: Current.parish_id, date: params[:date])
    authorize @event
    @event_types = EventType.active.ordered
  end

  # POST /events
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

  # GET /events/:id/edit
  def edit
    authorize @event
    @event_types = EventType.active.ordered
  end

  # PATCH /events/:id
  def update
    authorize @event
    if @event.update(event_params)
      redirect_to event_path(@event), notice: "일정이 수정되었습니다."
    else
      @event_types = EventType.active.ordered
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /events/:id
  def destroy
    authorize @event
    if @event.has_assignments?
      redirect_to event_path(@event), alert: "배정된 봉사자가 있어 삭제할 수 없습니다."
    else
      @event.destroy
      redirect_to events_path, notice: "일정이 삭제되었습니다."
    end
  end

  # GET /events/bulk_new
  def bulk_new
    authorize Event, :bulk_create?
    @event_types = EventType.active.ordered
  end

  # POST /events/bulk_create
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

  # DELETE /events/destroy_recurring
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
    day_of_week = params[:day_of_week].to_i  # 0=일, 1=월, ..., 6=토
    weeks = [params[:weeks].to_i, 12].min     # 최대 12주
    start_date = Date.parse(params[:start_date])
    group_id = SecureRandom.uuid

    created = 0
    events = []

    weeks.times do |i|
      date = start_date + (i * 7).days
      # 요일 맞추기
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
```

**액션 목록 (9개):**
- `index` - 목록 (필터 적용)
- `show` - 상세 (배정 현황 요약)
- `new` - 단건 생성 폼
- `create` - 단건 생성
- `edit` - 수정 폼
- `update` - 수정
- `destroy` - 삭제 (배정 없는 경우만)
- `bulk_new` - 반복 일정 생성 폼
- `bulk_create` - 반복 일정 생성
- `destroy_recurring` - 반복 그룹 일괄 삭제

---

## 4. Routes

```ruby
Rails.application.routes.draw do
  # Authentication
  resource :session, only: %i[new create destroy]
  resource :password, only: %i[edit update]

  # Members
  resources :members do
    member do
      patch :toggle_active
    end
  end

  # Events
  resources :events do
    collection do
      get :bulk_new
      post :bulk_create
      delete :destroy_recurring
    end
  end

  # Profile
  resource :profile, only: [:show]

  # Admin
  namespace :admin do
    resources :users
    resources :roles do
      member do
        patch :toggle_active
      end
    end
    resources :event_types do
      member do
        patch :toggle_active
      end
      resources :event_role_requirements, only: %i[create update destroy]
    end
  end

  root "dashboard#index"
  get "up" => "rails/health#show", as: :rails_health_check
end
```

**추가된 라우트:**
- `GET /events` → `events#index`
- `GET /events/new` → `events#new`
- `POST /events` → `events#create`
- `GET /events/bulk_new` → `events#bulk_new`
- `POST /events/bulk_create` → `events#bulk_create`
- `DELETE /events/destroy_recurring` → `events#destroy_recurring`
- `GET /events/:id` → `events#show`
- `GET /events/:id/edit` → `events#edit`
- `PATCH /events/:id` → `events#update`
- `DELETE /events/:id` → `events#destroy`

---

## 5. Views

### 5.1 index (`app/views/events/index.html.erb`)

```erb
<div class="flex justify-between items-center mb-6">
  <h1 class="text-2xl font-bold">일정 관리</h1>
  <div class="flex gap-2">
    <% if policy(Event).create? %>
      <%= link_to "새 일정", new_event_path, class: "bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700" %>
    <% end %>
    <% if policy(Event).bulk_create? %>
      <%= link_to "반복 일정", bulk_new_events_path, class: "bg-green-600 text-white px-4 py-2 rounded hover:bg-green-700" %>
    <% end %>
  </div>
</div>

<!-- 필터 -->
<div class="bg-white rounded-lg shadow p-4 mb-6">
  <%= form_tag events_path, method: :get, class: "flex flex-wrap gap-4 items-end" do %>
    <div>
      <%= label_tag :event_type_id, "미사유형", class: "block text-sm text-gray-500" %>
      <%= select_tag :event_type_id,
          options_from_collection_for_select(@event_types, :id, :name, params[:event_type_id]),
          include_blank: "전체", class: "mt-1 rounded-md border-gray-300 shadow-sm" %>
    </div>
    <div>
      <%= label_tag :from, "시작일", class: "block text-sm text-gray-500" %>
      <%= date_field_tag :from, params[:from], class: "mt-1 rounded-md border-gray-300 shadow-sm" %>
    </div>
    <div>
      <%= label_tag :to, "종료일", class: "block text-sm text-gray-500" %>
      <%= date_field_tag :to, params[:to], class: "mt-1 rounded-md border-gray-300 shadow-sm" %>
    </div>
    <%= submit_tag "검색", class: "bg-gray-600 text-white px-4 py-2 rounded hover:bg-gray-700 cursor-pointer" %>
    <%= link_to "초기화", events_path, class: "text-gray-500 hover:text-gray-700 py-2" %>
  <% end %>

  <div class="flex gap-4 mt-3">
    <%= link_to "다가오는 일정", events_path, class: "text-sm #{params[:view].blank? ? 'text-blue-600 font-bold' : 'text-gray-500 hover:text-gray-700'}" %>
    <%= link_to "지난 일정", events_path(view: "past"), class: "text-sm #{params[:view] == 'past' ? 'text-blue-600 font-bold' : 'text-gray-500 hover:text-gray-700'}" %>
  </div>
</div>

<!-- 일정 목록 -->
<table class="min-w-full bg-white rounded-lg shadow">
  <thead class="bg-gray-50">
    <tr>
      <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">날짜</th>
      <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">시간</th>
      <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">미사유형</th>
      <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">제목</th>
      <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">장소</th>
      <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">관리</th>
    </tr>
  </thead>
  <tbody>
    <% @events.each do |event| %>
      <tr class="border-t">
        <td class="px-6 py-4"><%= event.date.strftime("%Y-%m-%d (%a)") %></td>
        <td class="px-6 py-4 text-gray-500"><%= event.start_time.strftime("%H:%M") %></td>
        <td class="px-6 py-4"><%= event.event_type.name %></td>
        <td class="px-6 py-4"><%= event.title || "-" %></td>
        <td class="px-6 py-4 text-gray-500"><%= event.location || "-" %></td>
        <td class="px-6 py-4">
          <%= link_to "보기", event_path(event), class: "text-blue-600 hover:text-blue-800" %>
        </td>
      </tr>
    <% end %>
  </tbody>
</table>

<% if @events.empty? %>
  <p class="text-gray-500 text-center py-8">등록된 일정이 없습니다.</p>
<% end %>
```

### 5.2 show (`app/views/events/show.html.erb`)

```erb
<div class="max-w-3xl mx-auto">
  <div class="bg-white rounded-lg shadow p-8 mb-6">
    <div class="flex justify-between items-center mb-6">
      <h1 class="text-2xl font-bold"><%= @event.display_name %></h1>
      <% if @event.recurring_group_id.present? %>
        <span class="bg-purple-100 text-purple-800 px-3 py-1 rounded-full text-sm">반복 일정</span>
      <% end %>
    </div>

    <dl class="grid grid-cols-2 gap-4">
      <div>
        <dt class="text-sm text-gray-500">날짜</dt>
        <dd class="font-medium"><%= @event.date.strftime("%Y-%m-%d (%A)") %></dd>
      </div>
      <div>
        <dt class="text-sm text-gray-500">시간</dt>
        <dd><%= @event.start_time.strftime("%H:%M") %><%= " ~ #{@event.end_time.strftime('%H:%M')}" if @event.end_time %></dd>
      </div>
      <div>
        <dt class="text-sm text-gray-500">미사유형</dt>
        <dd><%= @event.event_type.name %></dd>
      </div>
      <div>
        <dt class="text-sm text-gray-500">장소</dt>
        <dd><%= @event.location || "-" %></dd>
      </div>
      <% if @event.notes.present? %>
        <div class="col-span-2">
          <dt class="text-sm text-gray-500">비고</dt>
          <dd><%= @event.notes %></dd>
        </div>
      <% end %>
    </dl>

    <div class="mt-6 flex gap-4">
      <% if policy(@event).update? %>
        <%= link_to "수정", edit_event_path(@event), class: "bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700" %>
      <% end %>
      <% if policy(@event).destroy? && !@event.has_assignments? %>
        <%= button_to "삭제", event_path(@event), method: :delete,
            class: "bg-red-600 text-white px-4 py-2 rounded hover:bg-red-700",
            data: { turbo_confirm: "이 일정을 삭제하시겠습니까?" } %>
      <% end %>
      <%= link_to "목록", events_path, class: "text-gray-600 hover:text-gray-900 py-2" %>
    </div>
  </div>

  <!-- 배정 현황 요약 (F06에서 상세 구현) -->
  <div class="bg-white rounded-lg shadow p-8">
    <h2 class="text-lg font-bold mb-4">역할별 배정 현황</h2>
    <% if @assignment_summary.any? %>
      <table class="min-w-full">
        <thead class="bg-gray-50">
          <tr>
            <th class="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase">역할</th>
            <th class="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase">필요</th>
            <th class="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase">배정</th>
            <th class="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase">상태</th>
          </tr>
        </thead>
        <tbody>
          <% @assignment_summary.each do |summary| %>
            <tr class="border-t">
              <td class="px-4 py-3"><%= summary[:role].name %></td>
              <td class="px-4 py-3"><%= summary[:required] %>명</td>
              <td class="px-4 py-3"><%= summary[:assigned] %>명</td>
              <td class="px-4 py-3">
                <% if summary[:assigned] >= summary[:required] %>
                  <span class="text-green-600">완료</span>
                <% else %>
                  <span class="text-orange-600">부족 (<%= summary[:required] - summary[:assigned] %>명)</span>
                <% end %>
              </td>
            </tr>
          <% end %>
        </tbody>
      </table>
    <% else %>
      <p class="text-gray-500">이 미사유형에 역할 템플릿이 설정되지 않았습니다.</p>
    <% end %>
  </div>
</div>
```

### 5.3 _form (`app/views/events/_form.html.erb`)

```erb
<%= form_with model: event, class: "space-y-6" do |f| %>
  <% if event.errors.any? %>
    <div class="bg-red-100 text-red-800 p-4 rounded">
      <ul>
        <% event.errors.full_messages.each do |msg| %>
          <li><%= msg %></li>
        <% end %>
      </ul>
    </div>
  <% end %>

  <div>
    <%= f.label :event_type_id, "미사유형", class: "block text-sm font-medium text-gray-700" %>
    <%= f.select :event_type_id, @event_types.map { |et| ["#{et.name} (#{et.total_required_count}명)", et.id] },
        { prompt: "선택..." },
        { class: "mt-1 block w-full rounded-md border-gray-300 shadow-sm",
          data: { action: "change->event-form#updateDefaultTime" } } %>
  </div>

  <div>
    <%= f.label :date, "날짜", class: "block text-sm font-medium text-gray-700" %>
    <%= f.date_field :date, class: "mt-1 block w-full rounded-md border-gray-300 shadow-sm", required: true %>
  </div>

  <div class="grid grid-cols-2 gap-4">
    <div>
      <%= f.label :start_time, "시작시간", class: "block text-sm font-medium text-gray-700" %>
      <%= f.time_field :start_time, class: "mt-1 block w-full rounded-md border-gray-300 shadow-sm", required: true %>
    </div>
    <div>
      <%= f.label :end_time, "종료시간", class: "block text-sm font-medium text-gray-700" %>
      <%= f.time_field :end_time, class: "mt-1 block w-full rounded-md border-gray-300 shadow-sm" %>
    </div>
  </div>

  <div>
    <%= f.label :title, "제목 (선택)", class: "block text-sm font-medium text-gray-700" %>
    <%= f.text_field :title, class: "mt-1 block w-full rounded-md border-gray-300 shadow-sm",
        placeholder: "미입력 시 '미사유형 (날짜)' 로 표시" %>
  </div>

  <div>
    <%= f.label :location, "장소", class: "block text-sm font-medium text-gray-700" %>
    <%= f.text_field :location, class: "mt-1 block w-full rounded-md border-gray-300 shadow-sm" %>
  </div>

  <div>
    <%= f.label :notes, "비고", class: "block text-sm font-medium text-gray-700" %>
    <%= f.text_area :notes, rows: 3, class: "mt-1 block w-full rounded-md border-gray-300 shadow-sm" %>
  </div>

  <div class="flex gap-4">
    <%= f.submit event.persisted? ? "수정" : "등록",
        class: "bg-blue-600 text-white px-6 py-2 rounded hover:bg-blue-700 cursor-pointer" %>
    <%= link_to "취소", event.persisted? ? event_path(event) : events_path,
        class: "text-gray-600 hover:text-gray-900 py-2" %>
  </div>
<% end %>
```

### 5.4 new (`app/views/events/new.html.erb`)

```erb
<div class="max-w-2xl mx-auto">
  <h1 class="text-2xl font-bold mb-6">일정 등록</h1>
  <div class="bg-white rounded-lg shadow p-8">
    <%= render "form", event: @event %>
  </div>
</div>
```

### 5.5 edit (`app/views/events/edit.html.erb`)

```erb
<div class="max-w-2xl mx-auto">
  <h1 class="text-2xl font-bold mb-6">일정 수정</h1>
  <div class="bg-white rounded-lg shadow p-8">
    <%= render "form", event: @event %>
  </div>
</div>
```

### 5.6 bulk_new (`app/views/events/bulk_new.html.erb`)

```erb
<div class="max-w-2xl mx-auto">
  <h1 class="text-2xl font-bold mb-6">반복 일정 생성</h1>
  <div class="bg-white rounded-lg shadow p-8">
    <%= form_tag bulk_create_events_path, class: "space-y-6" do %>

      <div>
        <%= label_tag :event_type_id, "미사유형", class: "block text-sm font-medium text-gray-700" %>
        <%= select_tag :event_type_id,
            options_from_collection_for_select(@event_types, :id, :name),
            prompt: "선택...", class: "mt-1 block w-full rounded-md border-gray-300 shadow-sm" %>
      </div>

      <div>
        <%= label_tag :day_of_week, "요일", class: "block text-sm font-medium text-gray-700" %>
        <%= select_tag :day_of_week,
            options_for_select([["일요일", 0], ["월요일", 1], ["화요일", 2], ["수요일", 3], ["목요일", 4], ["금요일", 5], ["토요일", 6]]),
            class: "mt-1 block w-full rounded-md border-gray-300 shadow-sm" %>
      </div>

      <div>
        <%= label_tag :start_date, "시작일", class: "block text-sm font-medium text-gray-700" %>
        <%= date_field_tag :start_date, Date.current, class: "mt-1 block w-full rounded-md border-gray-300 shadow-sm" %>
      </div>

      <div>
        <%= label_tag :weeks, "주 수 (최대 12주)", class: "block text-sm font-medium text-gray-700" %>
        <%= number_field_tag :weeks, 4, min: 1, max: 12, class: "mt-1 block w-full rounded-md border-gray-300 shadow-sm" %>
      </div>

      <p class="text-sm text-gray-500">
        선택한 미사유형의 기본시간이 자동 적용됩니다.
        생성된 일정은 같은 반복 그룹으로 묶여 일괄 관리할 수 있습니다.
      </p>

      <div class="flex gap-4">
        <%= submit_tag "생성", class: "bg-green-600 text-white px-6 py-2 rounded hover:bg-green-700 cursor-pointer" %>
        <%= link_to "취소", events_path, class: "text-gray-600 hover:text-gray-900 py-2" %>
      </div>
    <% end %>
  </div>
</div>
```

---

## 6. Navigation Updates

### 6.1 Navbar (`app/views/layouts/_navbar.html.erb`)

```erb
<nav class="bg-white shadow">
  <div class="container mx-auto px-4">
    <div class="flex justify-between items-center h-16">
      <div class="flex items-center space-x-8">
        <%= link_to "성단 매니저", root_path, class: "text-xl font-bold text-blue-600" %>
        <% if Current.user&.admin? || Current.user&.operator? %>
          <%= link_to "봉사자", members_path, class: "text-gray-600 hover:text-gray-900" %>
          <%= link_to "일정", events_path, class: "text-gray-600 hover:text-gray-900" %>
        <% end %>
        <% if Current.user&.admin? %>
          <%= link_to "역할", admin_roles_path, class: "text-gray-600 hover:text-gray-900" %>
          <%= link_to "미사유형", admin_event_types_path, class: "text-gray-600 hover:text-gray-900" %>
          <%= link_to "사용자 관리", admin_users_path, class: "text-gray-600 hover:text-gray-900" %>
        <% end %>
      </div>

      <div class="flex items-center space-x-4">
        <span class="text-sm text-gray-600"><%= Current.user&.name %> (<%= Current.user&.role %>)</span>
        <% if Current.user&.member_role? %>
          <%= link_to "내 프로필", profile_path, class: "text-sm text-gray-600 hover:text-gray-900" %>
        <% end %>
        <%= link_to "비밀번호 변경", edit_password_path, class: "text-sm text-gray-600 hover:text-gray-900" %>
        <%= button_to "로그아웃", session_path, method: :delete, class: "text-sm text-red-600 hover:text-red-800" %>
      </div>
    </div>
  </div>
</nav>
```

**변경사항:** `일정` 링크 추가 (admin + operator 접근)

### 6.2 Dashboard (`app/views/dashboard/index.html.erb`)

operator/admin 영역에 "일정 관리" 카드 추가:

```erb
<% if Current.user.admin? || Current.user.operator? %>
  <div class="bg-white rounded-lg shadow p-6">
    <h3 class="font-bold text-gray-700">일정 관리</h3>
    <%= link_to "일정 목록", events_path, class: "text-blue-600 hover:text-blue-800" %>
  </div>
<% end %>
```

---

## 7. ApplicationController Update

`skip_authorization?`에 변경 불필요. EventsController는 모든 액션에서 `authorize`를 호출합니다.

---

## 8. Test Plan

### 8.1 Request Spec (`spec/requests/events_spec.rb`)

| # | Test | Expected |
|---|------|----------|
| 1 | admin: GET /events returns success | 200, 목록 표시 |
| 2 | admin: GET /events with event_type_id filter | 해당 유형만 표시 |
| 3 | admin: GET /events with view=past | 지난 일정 표시 |
| 4 | admin: GET /events/:id shows event | 200, 상세 표시 |
| 5 | admin: GET /events/:id shows assignment summary | 역할별 배정 현황 |
| 6 | admin: GET /events/new renders form | 200 |
| 7 | admin: POST /events creates event | Event +1, redirect |
| 8 | admin: PATCH /events/:id updates event | 필드 변경 확인 |
| 9 | admin: DELETE /events/:id deletes event (no assignments) | Event -1, redirect |
| 10 | admin: DELETE /events/:id with assignments is blocked | alert 메시지 |
| 11 | admin: GET /events/bulk_new renders form | 200 |
| 12 | admin: POST /events/bulk_create creates recurring events | Event +N, recurring_group_id |
| 13 | admin: POST /events/bulk_create with max 12 weeks limit | 최대 12개 생성 |
| 14 | admin: DELETE /events/destroy_recurring deletes group | group 삭제 |
| 15 | operator: GET /events returns success | 200 |
| 16 | operator: POST /events creates event | Event +1 |
| 17 | operator: DELETE /events/:id is forbidden | redirect, alert |
| 18 | operator: GET /events/bulk_new is forbidden | redirect |
| 19 | member: GET /events is forbidden | redirect |

### 8.2 Policy Spec (`spec/policies/event_policy_spec.rb`)

| # | Test | Expected |
|---|------|----------|
| 1 | admin: permits index? | true |
| 2 | admin: permits show? | true |
| 3 | admin: permits create? | true |
| 4 | admin: permits update? | true |
| 5 | admin: permits destroy? | true |
| 6 | operator: permits index? | true |
| 7 | operator: permits create? | true |
| 8 | operator: denies destroy? | false |
| 9 | member: denies index? | false |
| 10 | member: denies create? | false |

**Total: 29 tests** (19 request + 10 policy)

---

## 9. Implementation Checklist

### Phase A: Model Update (1 file)
- [ ] A1. `app/models/event.rb` — 3 scopes + 2 메서드 + Paginatable 추가

### Phase B: Policy (1 file)
- [ ] B1. `app/policies/event_policy.rb` — 생성

### Phase C: Controller (1 file)
- [ ] C1. `app/controllers/events_controller.rb` — 생성 (9 액션)

### Phase D: Views (6 files)
- [ ] D1. `app/views/events/index.html.erb` — 목록 + 필터
- [ ] D2. `app/views/events/show.html.erb` — 상세 + 배정 현황
- [ ] D3. `app/views/events/_form.html.erb` — 단건 폼
- [ ] D4. `app/views/events/new.html.erb` — 등록 래퍼
- [ ] D5. `app/views/events/edit.html.erb` — 수정 래퍼
- [ ] D6. `app/views/events/bulk_new.html.erb` — 반복 생성 폼

### Phase E: Routes & Navigation (3 files 수정)
- [ ] E1. `config/routes.rb` — events 리소스 추가
- [ ] E2. `app/views/layouts/_navbar.html.erb` — "일정" 링크 추가
- [ ] E3. `app/views/dashboard/index.html.erb` — "일정 관리" 카드 추가

### Phase F: Tests (2 files)
- [ ] F1. `spec/requests/events_spec.rb` — 19 tests
- [ ] F2. `spec/policies/event_policy_spec.rb` — 10 tests

**Total: 14 files** (3 new + 4 modified + 6 new views + 1 modified model)

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | 2026-02-16 | Initial F05 design | Claude |
