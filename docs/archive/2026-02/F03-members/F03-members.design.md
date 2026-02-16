# F03: Parish & Member Management - Design Document

> **Summary**: 봉사자(Member) CRUD + 검색/필터 + 개인정보 마스킹 + 프로필 상세 설계
>
> **Project**: AltarServe Manager (성단 매니저)
> **Version**: 0.1.0
> **Author**: CTO Lead (Architect)
> **Date**: 2026-02-16
> **Status**: Draft
> **Planning Doc**: [F03-members.plan.md](../../01-plan/features/F03-members.plan.md)

---

## 1. Overview

### 1.1 Design Goals

1. 봉사자 CRUD (등록/조회/수정/비활성화) UI 구현
2. 검색 (이름/세례명/구역) + 필터 (활동상태/세례/견진/구역) 기능
3. 개인정보 마스킹 뷰 적용 (Maskable concern 활용)
4. 본인 프로필 조회 (member 역할)
5. 기존 MemberPolicy RBAC 적용
6. Request spec + Policy spec 보완

### 1.2 Design Principles

- **Existing Model Reuse**: F01 Member 모델을 그대로 활용 (스키마 변경 없음)
- **Existing Policy Reuse**: F02 MemberPolicy를 그대로 활용 (toggle_active만 추가)
- **Privacy by Default**: 뷰에서 항상 `masked_*` 헬퍼 사용, admin만 원본 열람
- **Turbo Integration**: 검색/필터는 Turbo Frame으로 부분 업데이트

---

## 2. Controller Design

### 2.1 MembersController

```ruby
# app/controllers/members_controller.rb
class MembersController < ApplicationController
  before_action :set_member, only: %i[show edit update toggle_active]

  def index
    @members = policy_scope(Member)
    @members = filter_members(@members)
    @members = search_members(@members)
    @members = @members.order(:name).page(params[:page]).per(20)
    authorize Member
  end

  def show
    authorize @member
  end

  def new
    @member = Member.new(parish_id: Current.parish_id)
    authorize @member
  end

  def create
    @member = Member.new(member_params)
    @member.parish_id = Current.parish_id
    authorize @member

    if @member.save
      redirect_to member_path(@member), notice: "봉사자가 등록되었습니다."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @member
  end

  def update
    authorize @member
    if @member.update(member_params)
      redirect_to member_path(@member), notice: "봉사자 정보가 수정되었습니다."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def toggle_active
    authorize @member, :destroy?
    @member.update!(active: !@member.active)
    status = @member.active? ? "활성화" : "비활성화"
    redirect_to member_path(@member), notice: "봉사자가 #{status}되었습니다."
  end

  private

  def set_member
    @member = Member.find(params[:id])
  end

  def member_params
    params.require(:member).permit(
      :name, :baptismal_name, :phone, :email, :birth_date,
      :gender, :district, :group_name, :baptized, :confirmed,
      :notes, :user_id
    )
  end

  def search_members(scope)
    return scope if params[:q].blank?
    query = "%#{params[:q]}%"
    scope.where("name LIKE :q OR baptismal_name LIKE :q OR district LIKE :q", q: query)
  end

  def filter_members(scope)
    scope = scope.active if params[:active] == "true"
    scope = scope.inactive if params[:active] == "false"
    scope = scope.baptized if params[:baptized] == "true"
    scope = scope.confirmed if params[:confirmed] == "true"
    scope = scope.by_district(params[:district]) if params[:district].present?
    scope
  end
end
```

### 2.2 ProfileController

```ruby
# app/controllers/profile_controller.rb
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
```

### 2.3 MemberPolicy Update

```ruby
# app/policies/member_policy.rb (toggle_active는 destroy? 재사용)
# 변경 없음 - toggle_active 액션은 destroy? 정책을 사용
# authorize @member, :destroy? 로 호출
```

---

## 3. Routes Design

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
  end

  # Dashboard (root)
  root "dashboard#index"

  # Health check
  get "up" => "rails/health#show", as: :rails_health_check
end
```

---

## 4. View Design

### 4.1 Members Index (목록 + 검색 + 필터)

```erb
<%# app/views/members/index.html.erb %>
<div class="flex justify-between items-center mb-6">
  <h1 class="text-2xl font-bold">봉사자 관리</h1>
  <% if policy(Member).create? %>
    <%= link_to "새 봉사자", new_member_path, class: "bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700" %>
  <% end %>
</div>

<!-- 검색 + 필터 -->
<%= form_with url: members_path, method: :get, class: "bg-white rounded-lg shadow p-4 mb-6", data: { turbo_frame: "members_list" } do |f| %>
  <div class="grid grid-cols-1 md:grid-cols-4 gap-4">
    <div>
      <%= f.label :q, "검색", class: "block text-sm font-medium text-gray-700" %>
      <%= f.text_field :q, value: params[:q], placeholder: "이름, 세례명, 구역",
          class: "mt-1 block w-full rounded-md border-gray-300 shadow-sm" %>
    </div>
    <div>
      <%= f.label :active, "활동 상태", class: "block text-sm font-medium text-gray-700" %>
      <%= f.select :active, [["전체", ""], ["활동", "true"], ["비활동", "false"]],
          { selected: params[:active] }, class: "mt-1 block w-full rounded-md border-gray-300 shadow-sm" %>
    </div>
    <div>
      <%= f.label :baptized, "세례", class: "block text-sm font-medium text-gray-700" %>
      <%= f.select :baptized, [["전체", ""], ["세례", "true"]],
          { selected: params[:baptized] }, class: "mt-1 block w-full rounded-md border-gray-300 shadow-sm" %>
    </div>
    <div class="flex items-end">
      <%= f.submit "검색", class: "bg-gray-600 text-white px-4 py-2 rounded hover:bg-gray-700 cursor-pointer" %>
      <%= link_to "초기화", members_path, class: "ml-2 text-gray-600 hover:text-gray-900 py-2" %>
    </div>
  </div>
<% end %>

<!-- 목록 -->
<%= turbo_frame_tag "members_list" do %>
  <table class="min-w-full bg-white rounded-lg shadow">
    <thead class="bg-gray-50">
      <tr>
        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">이름</th>
        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">세례명</th>
        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">연락처</th>
        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">구역</th>
        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">상태</th>
        <th class="px-6 py-3 text-left text-xs font-medium text-gray-500 uppercase">관리</th>
      </tr>
    </thead>
    <tbody>
      <% @members.each do |member| %>
        <tr class="border-t">
          <td class="px-6 py-4"><%= member.name %></td>
          <td class="px-6 py-4"><%= member.baptismal_name %></td>
          <td class="px-6 py-4"><%= member.masked_phone %></td>
          <td class="px-6 py-4"><%= member.district %></td>
          <td class="px-6 py-4">
            <span class="<%= member.active? ? 'text-green-600' : 'text-red-600' %>">
              <%= member.active? ? "활동" : "비활동" %>
            </span>
          </td>
          <td class="px-6 py-4">
            <%= link_to "보기", member_path(member), class: "text-blue-600 hover:text-blue-800" %>
          </td>
        </tr>
      <% end %>
    </tbody>
  </table>

  <!-- 페이지네이션 -->
  <div class="mt-4">
    <%# Kaminari 또는 Pagy 페이지네이션 (MVP는 수동 구현) %>
  </div>
<% end %>
```

### 4.2 Members Show (상세 - 마스킹 적용)

```erb
<%# app/views/members/show.html.erb %>
<div class="max-w-2xl mx-auto bg-white rounded-lg shadow p-8">
  <div class="flex justify-between items-center mb-6">
    <h1 class="text-2xl font-bold"><%= @member.name %></h1>
    <span class="<%= @member.active? ? 'bg-green-100 text-green-800' : 'bg-red-100 text-red-800' %> px-3 py-1 rounded-full text-sm">
      <%= @member.active? ? "활동" : "비활동" %>
    </span>
  </div>

  <dl class="space-y-4">
    <div><dt class="text-sm text-gray-500">세례명</dt><dd><%= @member.baptismal_name %></dd></div>
    <div><dt class="text-sm text-gray-500">연락처</dt><dd><%= @member.masked_phone %></dd></div>
    <div><dt class="text-sm text-gray-500">이메일</dt><dd><%= @member.masked_email %></dd></div>
    <div><dt class="text-sm text-gray-500">생년월일</dt><dd><%= @member.masked_birth_date %></dd></div>
    <div><dt class="text-sm text-gray-500">성별</dt><dd><%= @member.gender %></dd></div>
    <div><dt class="text-sm text-gray-500">구역</dt><dd><%= @member.district %></dd></div>
    <div><dt class="text-sm text-gray-500">단체</dt><dd><%= @member.group_name %></dd></div>
    <div><dt class="text-sm text-gray-500">세례</dt><dd><%= @member.baptized? ? "O" : "X" %></dd></div>
    <div><dt class="text-sm text-gray-500">견진</dt><dd><%= @member.confirmed? ? "O" : "X" %></dd></div>
    <% if @member.notes.present? %>
      <div><dt class="text-sm text-gray-500">메모</dt><dd><%= @member.notes %></dd></div>
    <% end %>
    <div><dt class="text-sm text-gray-500">등록일</dt><dd><%= @member.created_at.strftime("%Y-%m-%d") %></dd></div>
  </dl>

  <div class="mt-6 flex gap-4">
    <% if policy(@member).update? %>
      <%= link_to "수정", edit_member_path(@member), class: "bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700" %>
    <% end %>
    <% if policy(@member).destroy? %>
      <%= button_to @member.active? ? "비활성화" : "활성화",
          toggle_active_member_path(@member), method: :patch,
          class: "#{@member.active? ? 'bg-red-600 hover:bg-red-700' : 'bg-green-600 hover:bg-green-700'} text-white px-4 py-2 rounded" %>
    <% end %>
    <%= link_to "목록", members_path, class: "text-gray-600 hover:text-gray-900 py-2" %>
  </div>
</div>
```

### 4.3 Members Form (등록/수정)

```erb
<%# app/views/members/_form.html.erb %>
<%= form_with model: member, class: "space-y-4" do |f| %>
  <% if member.errors.any? %>
    <div class="bg-red-100 text-red-800 p-3 rounded">
      <ul>
        <% member.errors.full_messages.each do |message| %>
          <li><%= message %></li>
        <% end %>
      </ul>
    </div>
  <% end %>

  <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
    <div>
      <%= f.label :name, "이름 *", class: "block text-sm font-medium text-gray-700" %>
      <%= f.text_field :name, required: true, class: "mt-1 block w-full rounded-md border-gray-300 shadow-sm" %>
    </div>
    <div>
      <%= f.label :baptismal_name, "세례명", class: "block text-sm font-medium text-gray-700" %>
      <%= f.text_field :baptismal_name, class: "mt-1 block w-full rounded-md border-gray-300 shadow-sm" %>
    </div>
    <div>
      <%= f.label :phone, "연락처", class: "block text-sm font-medium text-gray-700" %>
      <%= f.telephone_field :phone, placeholder: "010-1234-5678", class: "mt-1 block w-full rounded-md border-gray-300 shadow-sm" %>
    </div>
    <div>
      <%= f.label :email, "이메일", class: "block text-sm font-medium text-gray-700" %>
      <%= f.email_field :email, class: "mt-1 block w-full rounded-md border-gray-300 shadow-sm" %>
    </div>
    <div>
      <%= f.label :birth_date, "생년월일", class: "block text-sm font-medium text-gray-700" %>
      <%= f.date_field :birth_date, class: "mt-1 block w-full rounded-md border-gray-300 shadow-sm" %>
    </div>
    <div>
      <%= f.label :gender, "성별", class: "block text-sm font-medium text-gray-700" %>
      <%= f.select :gender, [["선택 안 함", ""], ["남", "M"], ["여", "F"]],
          {}, class: "mt-1 block w-full rounded-md border-gray-300 shadow-sm" %>
    </div>
    <div>
      <%= f.label :district, "구역", class: "block text-sm font-medium text-gray-700" %>
      <%= f.text_field :district, class: "mt-1 block w-full rounded-md border-gray-300 shadow-sm" %>
    </div>
    <div>
      <%= f.label :group_name, "단체", class: "block text-sm font-medium text-gray-700" %>
      <%= f.text_field :group_name, class: "mt-1 block w-full rounded-md border-gray-300 shadow-sm" %>
    </div>
  </div>

  <div class="flex gap-6">
    <label class="flex items-center">
      <%= f.check_box :baptized, class: "rounded border-gray-300 text-blue-600" %>
      <span class="ml-2 text-sm text-gray-700">세례</span>
    </label>
    <label class="flex items-center">
      <%= f.check_box :confirmed, class: "rounded border-gray-300 text-blue-600" %>
      <span class="ml-2 text-sm text-gray-700">견진</span>
    </label>
  </div>

  <% if Current.user.admin? %>
    <div>
      <%= f.label :user_id, "연결 사용자 (선택)", class: "block text-sm font-medium text-gray-700" %>
      <%= f.select :user_id, User.all.map { |u| [u.name, u.id] },
          { include_blank: "연결 안 함" }, class: "mt-1 block w-full rounded-md border-gray-300 shadow-sm" %>
    </div>
  <% end %>

  <div>
    <%= f.label :notes, "메모", class: "block text-sm font-medium text-gray-700" %>
    <%= f.text_area :notes, rows: 3, class: "mt-1 block w-full rounded-md border-gray-300 shadow-sm" %>
  </div>

  <%= f.submit member.new_record? ? "등록" : "수정", class: "bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700 cursor-pointer" %>
<% end %>
```

### 4.4 Members New/Edit

```erb
<%# app/views/members/new.html.erb %>
<div class="max-w-2xl mx-auto bg-white rounded-lg shadow p-8">
  <h1 class="text-xl font-bold mb-6">새 봉사자 등록</h1>
  <%= render "form", member: @member %>
</div>
```

```erb
<%# app/views/members/edit.html.erb %>
<div class="max-w-2xl mx-auto bg-white rounded-lg shadow p-8">
  <h1 class="text-xl font-bold mb-6">봉사자 수정: <%= @member.name %></h1>
  <%= render "form", member: @member %>
</div>
```

### 4.5 Profile Show

```erb
<%# app/views/profile/show.html.erb %>
<div class="max-w-2xl mx-auto bg-white rounded-lg shadow p-8">
  <h1 class="text-2xl font-bold mb-6">내 프로필</h1>

  <dl class="space-y-4">
    <div><dt class="text-sm text-gray-500">이름</dt><dd><%= @member.name %></dd></div>
    <div><dt class="text-sm text-gray-500">세례명</dt><dd><%= @member.baptismal_name %></dd></div>
    <div><dt class="text-sm text-gray-500">연락처</dt><dd><%= @member.masked_phone %></dd></div>
    <div><dt class="text-sm text-gray-500">이메일</dt><dd><%= @member.masked_email %></dd></div>
    <div><dt class="text-sm text-gray-500">구역</dt><dd><%= @member.district %></dd></div>
    <div><dt class="text-sm text-gray-500">단체</dt><dd><%= @member.group_name %></dd></div>
    <div><dt class="text-sm text-gray-500">세례</dt><dd><%= @member.baptized? ? "O" : "X" %></dd></div>
    <div><dt class="text-sm text-gray-500">견진</dt><dd><%= @member.confirmed? ? "O" : "X" %></dd></div>
  </dl>
</div>
```

### 4.6 Navbar Update

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

---

## 5. Pagination Design

MVP에서는 간단한 수동 페이지네이션을 사용합니다 (gem 의존 없이).

```ruby
# app/models/concerns/paginatable.rb
module Paginatable
  extend ActiveSupport::Concern

  class_methods do
    def page(page_number)
      page_number = [page_number.to_i, 1].max
      offset((page_number - 1) * per_page_count)
    end

    def per(count)
      limit(count)
    end

    def per_page_count
      20
    end
  end
end
```

```ruby
# app/models/member.rb (수정 - include 추가)
class Member < ApplicationRecord
  include ParishScoped
  include Auditable
  include Maskable
  include Paginatable
  # ... (기존 코드 유지)
end
```

---

## 6. Test Plan

### 6.1 Request Specs

```ruby
# spec/requests/members_spec.rb
RSpec.describe "Members", type: :request do
  let(:parish) { create(:parish) }
  let(:admin) { create(:user, :admin, parish: parish, password: "password123") }
  let(:operator) { create(:user, :operator, parish: parish, password: "password123") }
  let(:member_user) { create(:user, :member_role, parish: parish, password: "password123") }

  describe "as admin" do
    before { sign_in(admin) }

    it "GET /members returns success" # index
    it "GET /members?q=name searches members" # search
    it "GET /members?active=true filters active" # filter
    it "GET /members/:id shows member with unmasked data" # show (admin sees raw)
    it "GET /members/new renders form" # new
    it "POST /members creates member" # create
    it "GET /members/:id/edit renders form" # edit
    it "PATCH /members/:id updates member" # update
    it "PATCH /members/:id/toggle_active toggles status" # toggle_active
  end

  describe "as operator" do
    before { sign_in(operator) }

    it "GET /members returns success" # index allowed
    it "GET /members/:id shows member with masked data" # show (masked)
    it "PATCH /members/:id updates member" # update allowed
    it "POST /members is forbidden" # create denied
    it "PATCH /members/:id/toggle_active is forbidden" # toggle denied
  end

  describe "as member" do
    before { sign_in(member_user) }

    it "GET /members is forbidden" # index denied
  end
end

# spec/requests/profile_spec.rb
RSpec.describe "Profile", type: :request do
  let(:parish) { create(:parish) }
  let(:member_user) { create(:user, :member_role, parish: parish, password: "password123") }
  let!(:member) { create(:member, parish: parish, user: member_user) }

  before { sign_in(member_user) }

  it "GET /profile shows own profile" do
    get profile_path
    expect(response).to have_http_status(:ok)
    expect(response.body).to include(member.name)
  end

  it "redirects when no member linked" do
    member.destroy
    get profile_path
    expect(response).to redirect_to(root_path)
  end
end
```

### 6.2 Test Coverage Matrix

| Spec File | Type | Tests |
|-----------|------|:---:|
| spec/requests/members_spec.rb | Request | 11 |
| spec/requests/profile_spec.rb | Request | 2 |
| spec/policies/member_policy_spec.rb | Policy | (existing from F02, add toggle test) |
| **Total New** | | **~13** |

---

## 7. Implementation Order

### 7.1 Step-by-step Checklist

```
Phase A: Pagination Concern
  1. [ ] app/models/concerns/paginatable.rb 생성
  2. [ ] Member 모델에 include Paginatable 추가

Phase B: Controllers
  3. [ ] app/controllers/members_controller.rb 생성
  4. [ ] app/controllers/profile_controller.rb 생성

Phase C: Views
  5. [ ] app/views/members/index.html.erb 생성
  6. [ ] app/views/members/show.html.erb 생성
  7. [ ] app/views/members/_form.html.erb 생성
  8. [ ] app/views/members/new.html.erb 생성
  9. [ ] app/views/members/edit.html.erb 생성
  10. [ ] app/views/profile/show.html.erb 생성

Phase D: Routes & Navigation
  11. [ ] config/routes.rb 수정 (members, profile 추가)
  12. [ ] app/views/layouts/_navbar.html.erb 수정 (봉사자/프로필 메뉴)

Phase E: Dashboard Update
  13. [ ] app/views/dashboard/index.html.erb 수정 (봉사자 관리 카드)

Phase F: Tests
  14. [ ] spec/requests/members_spec.rb 생성
  15. [ ] spec/requests/profile_spec.rb 생성
```

---

## 8. Security Considerations

- [x] 개인정보 마스킹: 뷰에서 `masked_phone`, `masked_email`, `masked_birth_date` 사용
- [x] Admin만 원본 개인정보 열람 (Maskable concern이 Current.user.admin? 체크)
- [x] RBAC: MemberPolicy로 create(admin), update(operator+), index(operator+), show(본인+operator+)
- [x] ParishScoped: 타 본당 데이터 접근 불가
- [x] Auditable: CRUD 감사로그 자동 기록
- [x] toggle_active: destroy? 정책으로 admin만 가능 (soft delete)

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | 2026-02-16 | Initial design document | CTO Lead (Architect) |
