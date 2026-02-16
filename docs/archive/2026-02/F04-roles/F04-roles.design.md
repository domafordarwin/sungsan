# F04: Role & Event Type Templates - Design Document

> **Summary**: 역할(Role) CRUD + 미사유형(EventType) CRUD + 역할 템플릿(EventRoleRequirement) 관리 UI 상세 설계
>
> **Project**: AltarServe Manager (성단 매니저)
> **Version**: 0.1.0
> **Author**: CTO Lead (Architect)
> **Date**: 2026-02-16
> **Status**: Draft
> **Planning Doc**: [F04-roles.plan.md](../../01-plan/features/F04-roles.plan.md)

---

## 1. Overview

### 1.1 Design Goals

1. 역할(Role) CRUD UI - 정렬, 자격조건 설정, 활성화/비활성화
2. 미사유형(EventType) CRUD UI - 기본시간, 활성화/비활성화
3. 미사유형별 역할 템플릿(EventRoleRequirement) 관리 - 역할 추가/제거, 필요인원 설정
4. Pundit RBAC 적용 (admin: 전체, operator: 조회만)
5. Turbo Frame으로 템플릿 역할 추가/제거 inline 처리
6. Request spec + Policy spec 작성

### 1.2 Design Principles

- **Existing Model Reuse**: F01 Role, EventType, EventRoleRequirement 모델 그대로 활용 (스키마 변경 없음)
- **Admin Namespace**: 관리 기능이므로 `Admin::` 네임스페이스 하위 배치
- **Turbo Frame**: EventRoleRequirement 추가/삭제를 페이지 리로드 없이 처리
- **Auditable**: Role, EventRoleRequirement에 이미 적용, EventType에 추가

---

## 2. Model Updates

### 2.1 EventType - Auditable 추가

```ruby
# app/models/event_type.rb (수정)
class EventType < ApplicationRecord
  include ParishScoped
  include Auditable

  has_many :event_role_requirements, dependent: :destroy
  has_many :roles, through: :event_role_requirements
  has_many :events, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: { scope: :parish_id }

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:name) }

  def total_required_count
    event_role_requirements.sum(:required_count)
  end
end
```

### 2.2 Role - ordered scope 추가 확인

```ruby
# app/models/role.rb (변경 없음 - 이미 sort_order 정렬 지원)
class Role < ApplicationRecord
  include ParishScoped
  include Auditable

  has_many :event_role_requirements, dependent: :destroy
  has_many :assignments, dependent: :restrict_with_error

  validates :name, presence: true, uniqueness: { scope: :parish_id }
  validates :sort_order, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

  scope :active, -> { where(active: true) }
  scope :ordered, -> { order(:sort_order) }
end
```

### 2.3 EventRoleRequirement - 변경 없음

```ruby
# app/models/event_role_requirement.rb (변경 없음)
class EventRoleRequirement < ApplicationRecord
  include Auditable

  belongs_to :event_type
  belongs_to :role

  validates :required_count, presence: true,
    numericality: { only_integer: true, greater_than: 0 }
  validates :role_id, uniqueness: { scope: :event_type_id }
end
```

---

## 3. Controller Design

### 3.1 Admin::RolesController

```ruby
# app/controllers/admin/roles_controller.rb
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
```

### 3.2 Admin::EventTypesController

```ruby
# app/controllers/admin/event_types_controller.rb
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
```

### 3.3 Admin::EventRoleRequirementsController

```ruby
# app/controllers/admin/event_role_requirements_controller.rb
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
```

---

## 4. Policy Design

### 4.1 RolePolicy

```ruby
# app/policies/role_policy.rb
class RolePolicy < ApplicationPolicy
  def index?
    operator_or_admin?
  end

  def show?
    operator_or_admin?
  end

  def create?
    admin?
  end

  def update?
    admin?
  end

  def destroy?
    admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end
end
```

### 4.2 EventTypePolicy

```ruby
# app/policies/event_type_policy.rb
class EventTypePolicy < ApplicationPolicy
  def index?
    operator_or_admin?
  end

  def show?
    operator_or_admin?
  end

  def create?
    admin?
  end

  def update?
    admin?
  end

  def destroy?
    admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end
end
```

### 4.3 EventRoleRequirementPolicy

```ruby
# app/policies/event_role_requirement_policy.rb
class EventRoleRequirementPolicy < ApplicationPolicy
  def create?
    admin?
  end

  def update?
    admin?
  end

  def destroy?
    admin?
  end
end
```

---

## 5. Routes Design

```ruby
# config/routes.rb (수정)
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

  # Profile (본인)
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

  # Dashboard (root)
  root "dashboard#index"

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end
```

---

## 6. View Design

### 6.1 Roles Index (역할 목록)

```erb
<%# app/views/admin/roles/index.html.erb %>
<div class="flex justify-between items-center mb-6">
  <h1 class="text-2xl font-bold">역할 관리</h1>
  <% if policy(Role).create? %>
    <%= link_to "새 역할", new_admin_role_path, class: "bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700" %>
  <% end %>
</div>

<table class="min-w-full bg-white rounded-lg shadow">
  <thead class="bg-gray-50">
    <tr>
      <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">순서</th>
      <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">역할명</th>
      <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">자격조건</th>
      <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">상태</th>
      <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">관리</th>
    </tr>
  </thead>
  <tbody>
    <% @roles.each do |role| %>
      <tr class="border-t">
        <td class="px-6 py-4 text-gray-500"><%= role.sort_order %></td>
        <td class="px-6 py-4 font-medium"><%= role.name %></td>
        <td class="px-6 py-4 text-sm text-gray-500">
          <%= "세례" if role.requires_baptism? %>
          <%= "견진" if role.requires_confirmation? %>
          <%= "#{role.min_age}세+" if role.min_age.present? %>
        </td>
        <td class="px-6 py-4">
          <span class="<%= role.active? ? 'text-green-600' : 'text-red-600' %>">
            <%= role.active? ? "활성" : "비활성" %>
          </span>
        </td>
        <td class="px-6 py-4">
          <%= link_to "보기", admin_role_path(role), class: "text-blue-600 hover:text-blue-800" %>
        </td>
      </tr>
    <% end %>
  </tbody>
</table>
```

### 6.2 Roles Show (역할 상세)

```erb
<%# app/views/admin/roles/show.html.erb %>
<div class="max-w-2xl mx-auto bg-white rounded-lg shadow p-8">
  <div class="flex justify-between items-center mb-6">
    <h1 class="text-2xl font-bold"><%= @role.name %></h1>
    <span class="<%= @role.active? ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800' %> px-3 py-1 rounded-full text-sm">
      <%= @role.active? ? "활성" : "비활성" %>
    </span>
  </div>

  <dl class="space-y-4">
    <div><dt class="text-sm text-gray-500">설명</dt><dd><%= @role.description || "-" %></dd></div>
    <div><dt class="text-sm text-gray-500">정렬순서</dt><dd><%= @role.sort_order %></dd></div>
    <div><dt class="text-sm text-gray-500">최대인원</dt><dd><%= @role.max_members || "제한없음" %></dd></div>
    <div>
      <dt class="text-sm text-gray-500">자격조건</dt>
      <dd>
        <% conditions = [] %>
        <% conditions << "세례 필요" if @role.requires_baptism? %>
        <% conditions << "견진 필요" if @role.requires_confirmation? %>
        <% conditions << "#{@role.min_age}세 이상" if @role.min_age.present? %>
        <%= conditions.any? ? conditions.join(", ") : "없음" %>
      </dd>
    </div>
  </dl>

  <% if @event_types.any? %>
    <div class="mt-6">
      <h2 class="text-lg font-bold mb-3">이 역할이 필요한 미사유형</h2>
      <ul class="space-y-1">
        <% @event_types.each do |req| %>
          <li class="text-gray-700">
            <%= link_to req.event_type.name, admin_event_type_path(req.event_type), class: "text-blue-600 hover:text-blue-800" %>
            (<%= req.required_count %>명)
          </li>
        <% end %>
      </ul>
    </div>
  <% end %>

  <div class="mt-6 flex gap-4">
    <% if policy(@role).update? %>
      <%= link_to "수정", edit_admin_role_path(@role), class: "bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700" %>
    <% end %>
    <% if policy(@role).destroy? %>
      <%= button_to @role.active? ? "비활성화" : "활성화",
          toggle_active_admin_role_path(@role), method: :patch,
          class: "#{@role.active? ? 'bg-red-600 hover:bg-red-700' : 'bg-green-600 hover:bg-green-700'} text-white px-4 py-2 rounded" %>
    <% end %>
    <%= link_to "목록", admin_roles_path, class: "text-gray-600 hover:text-gray-900 py-2" %>
  </div>
</div>
```

### 6.3 Roles Form (등록/수정)

```erb
<%# app/views/admin/roles/_form.html.erb %>
<%= form_with model: [:admin, role], class: "space-y-4" do |f| %>
  <% if role.errors.any? %>
    <div class="bg-red-100 text-red-800 p-3 rounded">
      <ul>
        <% role.errors.full_messages.each do |message| %>
          <li><%= message %></li>
        <% end %>
      </ul>
    </div>
  <% end %>

  <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
    <div>
      <%= f.label :name, "역할명 *", class: "block text-sm font-medium text-gray-700" %>
      <%= f.text_field :name, required: true, placeholder: "예: 십자가봉사, 초봉사",
          class: "mt-1 block w-full rounded-md border-gray-300 shadow-sm" %>
    </div>
    <div>
      <%= f.label :sort_order, "정렬순서", class: "block text-sm font-medium text-gray-700" %>
      <%= f.number_field :sort_order, min: 0,
          class: "mt-1 block w-full rounded-md border-gray-300 shadow-sm" %>
    </div>
    <div>
      <%= f.label :max_members, "최대인원 (선택)", class: "block text-sm font-medium text-gray-700" %>
      <%= f.number_field :max_members, min: 1, placeholder: "미입력 시 제한없음",
          class: "mt-1 block w-full rounded-md border-gray-300 shadow-sm" %>
    </div>
    <div>
      <%= f.label :min_age, "최소연령 (선택)", class: "block text-sm font-medium text-gray-700" %>
      <%= f.number_field :min_age, min: 1, placeholder: "미입력 시 제한없음",
          class: "mt-1 block w-full rounded-md border-gray-300 shadow-sm" %>
    </div>
  </div>

  <div>
    <%= f.label :description, "설명", class: "block text-sm font-medium text-gray-700" %>
    <%= f.text_area :description, rows: 3,
        class: "mt-1 block w-full rounded-md border-gray-300 shadow-sm" %>
  </div>

  <div class="flex gap-6">
    <label class="flex items-center">
      <%= f.check_box :requires_baptism, class: "rounded border-gray-300 text-blue-600" %>
      <span class="ml-2 text-sm text-gray-700">세례 필요</span>
    </label>
    <label class="flex items-center">
      <%= f.check_box :requires_confirmation, class: "rounded border-gray-300 text-blue-600" %>
      <span class="ml-2 text-sm text-gray-700">견진 필요</span>
    </label>
  </div>

  <%= f.submit role.new_record? ? "등록" : "수정",
      class: "bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700 cursor-pointer" %>
<% end %>
```

### 6.4 Roles New/Edit

```erb
<%# app/views/admin/roles/new.html.erb %>
<div class="max-w-2xl mx-auto bg-white rounded-lg shadow p-8">
  <h1 class="text-xl font-bold mb-6">새 역할 등록</h1>
  <%= render "form", role: @role %>
</div>
```

```erb
<%# app/views/admin/roles/edit.html.erb %>
<div class="max-w-2xl mx-auto bg-white rounded-lg shadow p-8">
  <h1 class="text-xl font-bold mb-6">역할 수정: <%= @role.name %></h1>
  <%= render "form", role: @role %>
</div>
```

### 6.5 EventTypes Index (미사유형 목록)

```erb
<%# app/views/admin/event_types/index.html.erb %>
<div class="flex justify-between items-center mb-6">
  <h1 class="text-2xl font-bold">미사유형 관리</h1>
  <% if policy(EventType).create? %>
    <%= link_to "새 미사유형", new_admin_event_type_path, class: "bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700" %>
  <% end %>
</div>

<table class="min-w-full bg-white rounded-lg shadow">
  <thead class="bg-gray-50">
    <tr>
      <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">미사유형</th>
      <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">기본시간</th>
      <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">필요역할</th>
      <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">상태</th>
      <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">관리</th>
    </tr>
  </thead>
  <tbody>
    <% @event_types.each do |et| %>
      <tr class="border-t">
        <td class="px-6 py-4 font-medium"><%= et.name %></td>
        <td class="px-6 py-4 text-gray-500"><%= et.default_time&.strftime("%H:%M") || "-" %></td>
        <td class="px-6 py-4 text-gray-500"><%= et.total_required_count %>명</td>
        <td class="px-6 py-4">
          <span class="<%= et.active? ? 'text-green-600' : 'text-red-600' %>">
            <%= et.active? ? "활성" : "비활성" %>
          </span>
        </td>
        <td class="px-6 py-4">
          <%= link_to "보기", admin_event_type_path(et), class: "text-blue-600 hover:text-blue-800" %>
        </td>
      </tr>
    <% end %>
  </tbody>
</table>
```

### 6.6 EventTypes Show (미사유형 상세 + 역할 템플릿)

```erb
<%# app/views/admin/event_types/show.html.erb %>
<div class="max-w-3xl mx-auto">
  <div class="bg-white rounded-lg shadow p-8 mb-6">
    <div class="flex justify-between items-center mb-6">
      <h1 class="text-2xl font-bold"><%= @event_type.name %></h1>
      <span class="<%= @event_type.active? ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800' %> px-3 py-1 rounded-full text-sm">
        <%= @event_type.active? ? "활성" : "비활성" %>
      </span>
    </div>

    <dl class="space-y-4">
      <div><dt class="text-sm text-gray-500">설명</dt><dd><%= @event_type.description || "-" %></dd></div>
      <div><dt class="text-sm text-gray-500">기본시간</dt><dd><%= @event_type.default_time&.strftime("%H:%M") || "-" %></dd></div>
    </dl>

    <div class="mt-6 flex gap-4">
      <% if policy(@event_type).update? %>
        <%= link_to "수정", edit_admin_event_type_path(@event_type), class: "bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700" %>
      <% end %>
      <% if policy(@event_type).destroy? %>
        <%= button_to @event_type.active? ? "비활성화" : "활성화",
            toggle_active_admin_event_type_path(@event_type), method: :patch,
            class: "#{@event_type.active? ? 'bg-red-600 hover:bg-red-700' : 'bg-green-600 hover:bg-green-700'} text-white px-4 py-2 rounded" %>
      <% end %>
      <%= link_to "목록", admin_event_types_path, class: "text-gray-600 hover:text-gray-900 py-2" %>
    </div>
  </div>

  <!-- 역할 템플릿 -->
  <div class="bg-white rounded-lg shadow p-8">
    <div class="flex justify-between items-center mb-4">
      <h2 class="text-lg font-bold">역할 템플릿 (총 <%= @event_type.total_required_count %>명)</h2>
    </div>

    <% if @requirements.any? %>
      <table class="min-w-full mb-6">
        <thead class="bg-gray-50">
          <tr>
            <th class="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase">역할</th>
            <th class="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase">필요인원</th>
            <% if policy(EventRoleRequirement.new).destroy? %>
              <th class="px-4 py-2 text-left text-xs font-medium text-gray-500 uppercase">관리</th>
            <% end %>
          </tr>
        </thead>
        <tbody>
          <% @requirements.each do |req| %>
            <tr class="border-t">
              <td class="px-4 py-3">
                <%= link_to req.role.name, admin_role_path(req.role), class: "text-blue-600 hover:text-blue-800" %>
              </td>
              <td class="px-4 py-3">
                <% if policy(req).update? %>
                  <%= form_with model: [:admin, @event_type, req], class: "flex items-center gap-2" do |f| %>
                    <%= f.number_field :required_count, min: 1, value: req.required_count,
                        class: "w-16 rounded-md border-gray-300 shadow-sm text-center" %>
                    <%= f.submit "변경", class: "text-sm text-blue-600 hover:text-blue-800 cursor-pointer" %>
                  <% end %>
                <% else %>
                  <%= req.required_count %>명
                <% end %>
              </td>
              <% if policy(req).destroy? %>
                <td class="px-4 py-3">
                  <%= button_to "제거",
                      admin_event_type_event_role_requirement_path(@event_type, req),
                      method: :delete,
                      class: "text-red-600 hover:text-red-800 text-sm",
                      data: { turbo_confirm: "#{req.role.name} 역할을 제거하시겠습니까?" } %>
                </td>
              <% end %>
            </tr>
          <% end %>
        </tbody>
      </table>
    <% else %>
      <p class="text-gray-500 mb-6">아직 등록된 역할이 없습니다.</p>
    <% end %>

    <!-- 역할 추가 폼 -->
    <% if policy(EventRoleRequirement.new).create? && @available_roles.any? %>
      <div class="border-t pt-4">
        <h3 class="text-sm font-medium text-gray-700 mb-2">역할 추가</h3>
        <%= form_with model: [:admin, @event_type, EventRoleRequirement.new], class: "flex items-end gap-4" do |f| %>
          <div>
            <%= f.label :role_id, "역할", class: "block text-sm text-gray-500" %>
            <%= f.select :role_id, @available_roles.map { |r| [r.name, r.id] },
                { prompt: "선택..." }, class: "mt-1 rounded-md border-gray-300 shadow-sm" %>
          </div>
          <div>
            <%= f.label :required_count, "필요인원", class: "block text-sm text-gray-500" %>
            <%= f.number_field :required_count, min: 1, value: 1,
                class: "mt-1 w-20 rounded-md border-gray-300 shadow-sm text-center" %>
          </div>
          <%= f.submit "추가", class: "bg-green-600 text-white px-4 py-2 rounded hover:bg-green-700 cursor-pointer" %>
        <% end %>
      </div>
    <% end %>
  </div>
</div>
```

### 6.7 EventTypes Form (등록/수정)

```erb
<%# app/views/admin/event_types/_form.html.erb %>
<%= form_with model: [:admin, event_type], class: "space-y-4" do |f| %>
  <% if event_type.errors.any? %>
    <div class="bg-red-100 text-red-800 p-3 rounded">
      <ul>
        <% event_type.errors.full_messages.each do |message| %>
          <li><%= message %></li>
        <% end %>
      </ul>
    </div>
  <% end %>

  <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
    <div>
      <%= f.label :name, "미사유형명 *", class: "block text-sm font-medium text-gray-700" %>
      <%= f.text_field :name, required: true, placeholder: "예: 주일미사 1차, 평일미사",
          class: "mt-1 block w-full rounded-md border-gray-300 shadow-sm" %>
    </div>
    <div>
      <%= f.label :default_time, "기본시간", class: "block text-sm font-medium text-gray-700" %>
      <%= f.time_field :default_time,
          class: "mt-1 block w-full rounded-md border-gray-300 shadow-sm" %>
    </div>
  </div>

  <div>
    <%= f.label :description, "설명", class: "block text-sm font-medium text-gray-700" %>
    <%= f.text_area :description, rows: 3,
        class: "mt-1 block w-full rounded-md border-gray-300 shadow-sm" %>
  </div>

  <%= f.submit event_type.new_record? ? "등록" : "수정",
      class: "bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700 cursor-pointer" %>
<% end %>
```

### 6.8 EventTypes New/Edit

```erb
<%# app/views/admin/event_types/new.html.erb %>
<div class="max-w-2xl mx-auto bg-white rounded-lg shadow p-8">
  <h1 class="text-xl font-bold mb-6">새 미사유형 등록</h1>
  <%= render "form", event_type: @event_type %>
</div>
```

```erb
<%# app/views/admin/event_types/edit.html.erb %>
<div class="max-w-2xl mx-auto bg-white rounded-lg shadow p-8">
  <h1 class="text-xl font-bold mb-6">미사유형 수정: <%= @event_type.name %></h1>
  <%= render "form", event_type: @event_type %>
</div>
```

### 6.9 Navbar Update

```erb
<%# app/views/layouts/_navbar.html.erb (수정) %>
<nav class="bg-white shadow">
  <div class="container mx-auto px-4">
    <div class="flex justify-between items-center h-16">
      <div class="flex items-center space-x-8">
        <%= link_to "성단 매니저", root_path, class: "text-xl font-bold text-blue-600" %>
        <% if Current.user&.admin? || Current.user&.operator? %>
          <%= link_to "봉사자", members_path, class: "text-gray-600 hover:text-gray-900" %>
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

### 6.10 Dashboard Update

```erb
<%# app/views/dashboard/index.html.erb (수정) %>
<h1 class="text-2xl font-bold mb-6">대시보드</h1>
<p class="text-gray-600">안녕하세요, <%= Current.user.name %>님. (<%= Current.user.role %>)</p>

<div class="grid grid-cols-1 md:grid-cols-3 gap-6 mt-8">
  <% if Current.user.admin? || Current.user.operator? %>
    <div class="bg-white rounded-lg shadow p-6">
      <h3 class="font-bold text-gray-700">봉사자 관리</h3>
      <%= link_to "봉사자 목록", members_path, class: "text-blue-600 hover:text-blue-800" %>
    </div>
  <% end %>

  <% if Current.user.admin? %>
    <div class="bg-white rounded-lg shadow p-6">
      <h3 class="font-bold text-gray-700">역할 관리</h3>
      <%= link_to "역할 목록", admin_roles_path, class: "text-blue-600 hover:text-blue-800" %>
    </div>

    <div class="bg-white rounded-lg shadow p-6">
      <h3 class="font-bold text-gray-700">미사유형 관리</h3>
      <%= link_to "미사유형 목록", admin_event_types_path, class: "text-blue-600 hover:text-blue-800" %>
    </div>

    <div class="bg-white rounded-lg shadow p-6">
      <h3 class="font-bold text-gray-700">사용자 관리</h3>
      <%= link_to "사용자 목록", admin_users_path, class: "text-blue-600 hover:text-blue-800" %>
    </div>
  <% end %>

  <div class="bg-white rounded-lg shadow p-6">
    <h3 class="font-bold text-gray-700">내 정보</h3>
    <% if Current.user.member_role? && Current.user.member %>
      <%= link_to "내 프로필", profile_path, class: "text-blue-600 hover:text-blue-800" %>
      <br>
    <% end %>
    <%= link_to "비밀번호 변경", edit_password_path, class: "text-blue-600 hover:text-blue-800" %>
  </div>
</div>
```

---

## 7. Test Plan

### 7.1 Request Specs

```ruby
# spec/requests/admin/roles_spec.rb
RSpec.describe "Admin::Roles", type: :request do
  let(:parish) { create(:parish) }
  let(:admin) { create(:user, :admin, parish: parish, password: "password123") }
  let(:operator) { create(:user, :operator, parish: parish, password: "password123") }
  let(:member_user) { create(:user, :member_role, parish: parish, password: "password123") }
  let!(:role) { create(:role, parish: parish, name: "십자가봉사") }

  describe "as admin" do
    before { sign_in(admin) }

    it "GET /admin/roles returns success" do
      get admin_roles_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("십자가봉사")
    end

    it "GET /admin/roles/:id shows role" do
      get admin_role_path(role)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include(role.name)
    end

    it "GET /admin/roles/new renders form" do
      get new_admin_role_path
      expect(response).to have_http_status(:ok)
    end

    it "POST /admin/roles creates role" do
      expect {
        post admin_roles_path, params: { role: { name: "초봉사", sort_order: 1 } }
      }.to change(Role, :count).by(1)
      expect(response).to redirect_to(admin_role_path(Role.last))
    end

    it "PATCH /admin/roles/:id updates role" do
      patch admin_role_path(role), params: { role: { name: "향봉사" } }
      expect(role.reload.name).to eq("향봉사")
    end

    it "PATCH /admin/roles/:id/toggle_active toggles status" do
      patch toggle_active_admin_role_path(role)
      expect(role.reload.active).to be false
    end
  end

  describe "as operator" do
    before { sign_in(operator) }

    it "GET /admin/roles returns success" do
      get admin_roles_path
      expect(response).to have_http_status(:ok)
    end

    it "GET /admin/roles/:id shows role" do
      get admin_role_path(role)
      expect(response).to have_http_status(:ok)
    end

    it "POST /admin/roles is forbidden" do
      post admin_roles_path, params: { role: { name: "새역할", sort_order: 0 } }
      expect(response).to have_http_status(:forbidden).or redirect_to(root_path)
    end
  end

  describe "as member" do
    before { sign_in(member_user) }

    it "GET /admin/roles is forbidden" do
      get admin_roles_path
      expect(response).to have_http_status(:forbidden).or redirect_to(root_path)
    end
  end
end
```

```ruby
# spec/requests/admin/event_types_spec.rb
RSpec.describe "Admin::EventTypes", type: :request do
  let(:parish) { create(:parish) }
  let(:admin) { create(:user, :admin, parish: parish, password: "password123") }
  let(:operator) { create(:user, :operator, parish: parish, password: "password123") }
  let(:member_user) { create(:user, :member_role, parish: parish, password: "password123") }
  let!(:event_type) { create(:event_type, parish: parish, name: "주일미사 1차") }
  let!(:role) { create(:role, parish: parish, name: "십자가봉사") }

  describe "as admin" do
    before { sign_in(admin) }

    it "GET /admin/event_types returns success" do
      get admin_event_types_path
      expect(response).to have_http_status(:ok)
      expect(response.body).to include("주일미사 1차")
    end

    it "GET /admin/event_types/:id shows event type with template" do
      get admin_event_type_path(event_type)
      expect(response).to have_http_status(:ok)
    end

    it "POST /admin/event_types creates event type" do
      expect {
        post admin_event_types_path, params: { event_type: { name: "평일미사", default_time: "06:30" } }
      }.to change(EventType, :count).by(1)
      expect(response).to redirect_to(admin_event_type_path(EventType.last))
    end

    it "PATCH /admin/event_types/:id updates event type" do
      patch admin_event_type_path(event_type), params: { event_type: { name: "주일미사 2차" } }
      expect(event_type.reload.name).to eq("주일미사 2차")
    end

    it "PATCH /admin/event_types/:id/toggle_active toggles status" do
      patch toggle_active_admin_event_type_path(event_type)
      expect(event_type.reload.active).to be false
    end

    # EventRoleRequirement tests
    it "POST creates event role requirement" do
      expect {
        post admin_event_type_event_role_requirements_path(event_type),
            params: { event_role_requirement: { role_id: role.id, required_count: 2 } }
      }.to change(EventRoleRequirement, :count).by(1)
      expect(response).to redirect_to(admin_event_type_path(event_type))
    end

    it "PATCH updates event role requirement count" do
      req = create(:event_role_requirement, event_type: event_type, role: role, required_count: 1)
      patch admin_event_type_event_role_requirement_path(event_type, req),
          params: { event_role_requirement: { required_count: 3 } }
      expect(req.reload.required_count).to eq(3)
    end

    it "DELETE removes event role requirement" do
      req = create(:event_role_requirement, event_type: event_type, role: role)
      expect {
        delete admin_event_type_event_role_requirement_path(event_type, req)
      }.to change(EventRoleRequirement, :count).by(-1)
    end
  end

  describe "as operator" do
    before { sign_in(operator) }

    it "GET /admin/event_types returns success" do
      get admin_event_types_path
      expect(response).to have_http_status(:ok)
    end

    it "POST /admin/event_types is forbidden" do
      post admin_event_types_path, params: { event_type: { name: "새유형" } }
      expect(response).to have_http_status(:forbidden).or redirect_to(root_path)
    end
  end

  describe "as member" do
    before { sign_in(member_user) }

    it "GET /admin/event_types is forbidden" do
      get admin_event_types_path
      expect(response).to have_http_status(:forbidden).or redirect_to(root_path)
    end
  end
end
```

### 7.2 Policy Specs

```ruby
# spec/policies/role_policy_spec.rb
RSpec.describe RolePolicy, type: :policy do
  let(:parish) { create(:parish) }
  let(:admin) { create(:user, :admin, parish: parish) }
  let(:operator) { create(:user, :operator, parish: parish) }
  let(:member_user) { create(:user, :member_role, parish: parish) }
  let(:role) { create(:role, parish: parish) }

  permissions :index?, :show? do
    it "permits admin" do
      expect(described_class).to permit(admin, role)
    end

    it "permits operator" do
      expect(described_class).to permit(operator, role)
    end

    it "denies member" do
      expect(described_class).not_to permit(member_user, role)
    end
  end

  permissions :create?, :update?, :destroy? do
    it "permits admin" do
      expect(described_class).to permit(admin, role)
    end

    it "denies operator" do
      expect(described_class).not_to permit(operator, role)
    end

    it "denies member" do
      expect(described_class).not_to permit(member_user, role)
    end
  end
end
```

```ruby
# spec/policies/event_type_policy_spec.rb
RSpec.describe EventTypePolicy, type: :policy do
  let(:parish) { create(:parish) }
  let(:admin) { create(:user, :admin, parish: parish) }
  let(:operator) { create(:user, :operator, parish: parish) }
  let(:member_user) { create(:user, :member_role, parish: parish) }
  let(:event_type) { create(:event_type, parish: parish) }

  permissions :index?, :show? do
    it "permits admin" do
      expect(described_class).to permit(admin, event_type)
    end

    it "permits operator" do
      expect(described_class).to permit(operator, event_type)
    end

    it "denies member" do
      expect(described_class).not_to permit(member_user, event_type)
    end
  end

  permissions :create?, :update?, :destroy? do
    it "permits admin" do
      expect(described_class).to permit(admin, event_type)
    end

    it "denies operator" do
      expect(described_class).not_to permit(operator, event_type)
    end

    it "denies member" do
      expect(described_class).not_to permit(member_user, event_type)
    end
  end
end
```

### 7.3 Test Coverage Matrix

| Spec File | Type | Tests |
|-----------|------|:---:|
| spec/requests/admin/roles_spec.rb | Request | 9 |
| spec/requests/admin/event_types_spec.rb | Request | 10 |
| spec/policies/role_policy_spec.rb | Policy | 6 |
| spec/policies/event_type_policy_spec.rb | Policy | 6 |
| **Total** | | **31** |

---

## 8. Implementation Order

### 8.1 Step-by-step Checklist

```
Phase A: Model Updates (1 file)
  1. [ ] app/models/event_type.rb - include Auditable, ordered scope, total_required_count

Phase B: Policies (3 files)
  2. [ ] app/policies/role_policy.rb
  3. [ ] app/policies/event_type_policy.rb
  4. [ ] app/policies/event_role_requirement_policy.rb

Phase C: Controllers (3 files)
  5. [ ] app/controllers/admin/roles_controller.rb
  6. [ ] app/controllers/admin/event_types_controller.rb
  7. [ ] app/controllers/admin/event_role_requirements_controller.rb

Phase D: Role Views (5 files)
  8. [ ] app/views/admin/roles/index.html.erb
  9. [ ] app/views/admin/roles/show.html.erb
  10. [ ] app/views/admin/roles/_form.html.erb
  11. [ ] app/views/admin/roles/new.html.erb
  12. [ ] app/views/admin/roles/edit.html.erb

Phase E: EventType Views (5 files)
  13. [ ] app/views/admin/event_types/index.html.erb
  14. [ ] app/views/admin/event_types/show.html.erb (+ 역할 템플릿)
  15. [ ] app/views/admin/event_types/_form.html.erb
  16. [ ] app/views/admin/event_types/new.html.erb
  17. [ ] app/views/admin/event_types/edit.html.erb

Phase F: Routes & Navigation (3 files)
  18. [ ] config/routes.rb - admin/roles, admin/event_types, event_role_requirements
  19. [ ] app/views/layouts/_navbar.html.erb - 역할/미사유형 메뉴 추가
  20. [ ] app/views/dashboard/index.html.erb - 역할/미사유형 카드 추가

Phase G: Tests (4 files)
  21. [ ] spec/requests/admin/roles_spec.rb
  22. [ ] spec/requests/admin/event_types_spec.rb
  23. [ ] spec/policies/role_policy_spec.rb
  24. [ ] spec/policies/event_type_policy_spec.rb
```

**Total: 24 files (1 modify + 23 create)**

---

## 9. Security Considerations

- [x] RBAC: RolePolicy, EventTypePolicy (admin: CRUD, operator: index/show, member: 접근불가)
- [x] EventRoleRequirementPolicy: admin만 CRUD
- [x] ParishScoped: Role, EventType 자동 본당 격리
- [x] Auditable: Role, EventRoleRequirement 감사로그 자동 기록 (EventType에 추가)
- [x] soft delete: active 플래그 사용, dependent: restrict_with_error로 참조 무결성 보호
- [x] turbo_confirm: 역할 제거 시 확인 다이얼로그

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | 2026-02-16 | Initial design document | CTO Lead (Architect) |
