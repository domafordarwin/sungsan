# F02: User Authentication & Authorization - Design Document

> **Summary**: Rails 8 빌트인 인증 + Pundit RBAC 상세 설계
>
> **Project**: AltarServe Manager (성단 매니저)
> **Version**: 0.1.0
> **Author**: CTO Lead (Architect)
> **Date**: 2026-02-16
> **Status**: Draft
> **Planning Doc**: [F02-auth.plan.md](../../01-plan/features/F02-auth.plan.md)

---

## 1. Overview

### 1.1 Design Goals

1. Rails 8 스타일 세션 기반 인증 구현 (Authentication concern)
2. Pundit RBAC 3단계 권한 제어 (admin/operator/member)
3. Current attributes로 요청별 컨텍스트 설정
4. 관리자용 사용자 CRUD
5. 기본 레이아웃 + 네비게이션 구조
6. Request/Policy 스펙으로 인증/인가 검증

### 1.2 Design Principles

- **Rails 8 Convention**: 빌트인 인증 패턴 준수 (authenticate_by, session cookie)
- **Least Privilege**: 기본 정책은 거부, 명시적 허용만
- **Defense in Depth**: after_action :verify_authorized로 정책 누락 방지
- **Audit by Default**: 로그인/로그아웃/비밀번호 변경 감사로그 기록

---

## 2. Authentication Design

### 2.1 Authentication Concern

```ruby
# app/controllers/concerns/authentication.rb
module Authentication
  extend ActiveSupport::Concern

  included do
    before_action :require_authentication
    helper_method :authenticated?
  end

  class_methods do
    def allow_unauthenticated_access(**options)
      skip_before_action :require_authentication, **options
    end
  end

  private

  def authenticated?
    resume_session.present?
  end

  def require_authentication
    resume_session || request_authentication
  end

  def resume_session
    Current.session ||= find_session_by_cookie
  end

  def find_session_by_cookie
    if (id = cookies.signed[:session_id])
      Session.find_by(id: id)
    end
  end

  def request_authentication
    session[:return_to_after_authenticating] = request.url
    redirect_to new_session_path, alert: "로그인이 필요합니다."
  end

  def after_authentication_url
    session.delete(:return_to_after_authenticating) || root_path
  end

  def start_new_session_for(user)
    user.sessions.create!(
      ip_address: request.remote_ip,
      user_agent: request.user_agent
    ).tap do |new_session|
      Current.session = new_session
      cookies.signed.permanent[:session_id] = {
        value: new_session.id,
        httponly: true,
        same_site: :lax
      }
    end
  end

  def terminate_session
    Current.session.destroy
    cookies.delete(:session_id)
  end
end
```

### 2.2 Sessions Controller

```ruby
# app/controllers/sessions_controller.rb
class SessionsController < ApplicationController
  allow_unauthenticated_access only: [:new, :create]
  rate_limit to: 10, within: 3.minutes, only: :create, with: -> {
    redirect_to new_session_path, alert: "잠시 후 다시 시도해주세요."
  }

  def new
  end

  def create
    if (user = User.authenticate_by(email_address: params[:email_address], password: params[:password]))
      start_new_session_for(user)
      redirect_to after_authentication_url, notice: "로그인되었습니다."
    else
      redirect_to new_session_path, alert: "이메일 또는 비밀번호가 올바르지 않습니다."
    end
  end

  def destroy
    terminate_session
    redirect_to new_session_path, notice: "로그아웃되었습니다."
  end
end
```

### 2.3 Application Controller

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  include Authentication
  include Pundit::Authorization

  before_action :set_current_attributes
  after_action :verify_authorized, except: :index, unless: :skip_authorization?
  after_action :verify_policy_scoped, only: :index, unless: :skip_authorization?

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized

  private

  def set_current_attributes
    if Current.session
      Current.user = Current.session.user
      Current.parish_id = Current.user.parish_id
      Current.ip_address = request.remote_ip
      Current.user_agent = request.user_agent
    end
  end

  def user_not_authorized
    redirect_back fallback_location: root_path, alert: "접근 권한이 없습니다."
  end

  def skip_authorization?
    devise_controller? rescue false
  end
end
```

### 2.4 Session Model Update

```ruby
# app/models/session.rb (수정)
class Session < ApplicationRecord
  belongs_to :user

  # 세션에서 Current.user 접근 지원
  def user
    super
  end
end
```

### 2.5 Current Model (기존 유지)

```ruby
# app/models/current.rb (속성 추가)
class Current < ActiveSupport::CurrentAttributes
  attribute :user
  attribute :session
  attribute :parish_id
  attribute :ip_address
  attribute :user_agent

  def parish
    Parish.find(parish_id) if parish_id
  end
end
```

**변경점**: `attribute :session` 추가

---

## 3. Authorization Design (Pundit)

### 3.1 Application Policy

```ruby
# app/policies/application_policy.rb
class ApplicationPolicy
  attr_reader :user, :record

  def initialize(user, record)
    @user = user
    @record = record
  end

  # 기본: 모두 거부
  def index?
    false
  end

  def show?
    false
  end

  def create?
    false
  end

  def new?
    create?
  end

  def update?
    false
  end

  def edit?
    update?
  end

  def destroy?
    false
  end

  def admin?
    user&.admin?
  end

  def operator_or_admin?
    user&.admin? || user&.operator?
  end

  class Scope
    def initialize(user, scope)
      @user = user
      @scope = scope
    end

    def resolve
      raise NotImplementedError, "You must define #resolve in #{self.class}"
    end

    private

    attr_reader :user, :scope
  end
end
```

### 3.2 User Policy

```ruby
# app/policies/user_policy.rb
class UserPolicy < ApplicationPolicy
  def index?
    admin?
  end

  def show?
    admin? || record == user
  end

  def create?
    admin?
  end

  def update?
    admin?
  end

  def destroy?
    admin? && record != user # 자기 자신 삭제 불가
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.admin?
        scope.all
      else
        scope.where(id: user.id)
      end
    end
  end
end
```

### 3.3 F02 범위 추가 Policies (기본 설정)

```ruby
# app/policies/member_policy.rb
class MemberPolicy < ApplicationPolicy
  def index?
    operator_or_admin?
  end

  def show?
    operator_or_admin? || (record.user_id == user.id)
  end

  def create?
    admin?
  end

  def update?
    operator_or_admin?
  end

  def destroy?
    admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      if user.admin? || user.operator?
        scope.all
      else
        scope.where(user_id: user.id)
      end
    end
  end
end
```

### 3.4 RBAC Permission Matrix

| Resource | Action | admin | operator | member |
|----------|--------|:---:|:---:|:---:|
| User | index | O | X | X |
| User | show | O | X (본인만) | X (본인만) |
| User | create | O | X | X |
| User | update | O | X | X |
| User | destroy | O (본인 제외) | X | X |
| Member | index | O | O | X |
| Member | show | O | O | O (본인만) |
| Member | create | O | X | X |
| Member | update | O | O | X |
| Member | destroy | O | X | X |
| Dashboard | index | O | O | O |

---

## 4. Controller Design

### 4.1 Passwords Controller

```ruby
# app/controllers/passwords_controller.rb
class PasswordsController < ApplicationController
  def edit
    authorize Current.user, :show?
  end

  def update
    authorize Current.user, :show?
    if Current.user.update(password_params)
      redirect_to root_path, notice: "비밀번호가 변경되었습니다."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def password_params
    params.require(:user).permit(:password, :password_confirmation)
  end
end
```

### 4.2 Admin::Users Controller

```ruby
# app/controllers/admin/users_controller.rb
module Admin
  class UsersController < ApplicationController
    before_action :set_user, only: [:show, :edit, :update, :destroy]

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
```

### 4.3 Dashboard Controller

```ruby
# app/controllers/dashboard_controller.rb
class DashboardController < ApplicationController
  def index
    skip_authorization
  end
end
```

---

## 5. Routes Design

```ruby
# config/routes.rb
Rails.application.routes.draw do
  # 인증
  resource :session, only: [:new, :create, :destroy]
  resource :password, only: [:edit, :update]

  # 관리자
  namespace :admin do
    resources :users
  end

  # 대시보드 (루트)
  root "dashboard#index"

  # 헬스체크
  get "up" => "rails/health#show", as: :rails_health_check
end
```

---

## 6. View Design

### 6.1 Layout

```erb
<%# app/views/layouts/application.html.erb %>
<!DOCTYPE html>
<html lang="ko">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>AltarServe Manager</title>
  <%= csrf_meta_tags %>
  <%= csp_meta_tag %>
  <%= stylesheet_link_tag "application", "data-turbo-track": "reload" %>
  <%= javascript_importmap_tags %>
</head>
<body class="min-h-screen bg-gray-50">
  <% if authenticated? %>
    <nav class="bg-white shadow">
      <!-- 네비게이션 바 -->
      <!-- 로고, 메뉴, 사용자 정보, 로그아웃 -->
    </nav>
  <% end %>

  <% if notice %>
    <div class="bg-green-100 text-green-800 p-3"><%= notice %></div>
  <% end %>
  <% if alert %>
    <div class="bg-red-100 text-red-800 p-3"><%= alert %></div>
  <% end %>

  <main class="container mx-auto px-4 py-6">
    <%= yield %>
  </main>
</body>
</html>
```

### 6.2 Login Page

```erb
<%# app/views/sessions/new.html.erb %>
<div class="flex min-h-screen items-center justify-center">
  <div class="w-full max-w-md bg-white rounded-lg shadow p-8">
    <h1 class="text-2xl font-bold text-center mb-6">AltarServe Manager</h1>
    <h2 class="text-lg text-gray-600 text-center mb-8">성단 매니저 로그인</h2>

    <%= form_with url: session_path, method: :post, class: "space-y-4" do |f| %>
      <div>
        <%= f.label :email_address, "이메일", class: "block text-sm font-medium text-gray-700" %>
        <%= f.email_field :email_address, required: true, autofocus: true, autocomplete: "email",
            class: "mt-1 block w-full rounded-md border-gray-300 shadow-sm" %>
      </div>

      <div>
        <%= f.label :password, "비밀번호", class: "block text-sm font-medium text-gray-700" %>
        <%= f.password_field :password, required: true, autocomplete: "current-password",
            class: "mt-1 block w-full rounded-md border-gray-300 shadow-sm" %>
      </div>

      <%= f.submit "로그인", class: "w-full bg-blue-600 text-white rounded-md py-2 hover:bg-blue-700" %>
    <% end %>
  </div>
</div>
```

### 6.3 Password Change Page

```erb
<%# app/views/passwords/edit.html.erb %>
<div class="max-w-md mx-auto bg-white rounded-lg shadow p-8">
  <h1 class="text-xl font-bold mb-6">비밀번호 변경</h1>

  <%= form_with model: Current.user, url: password_path, method: :patch, class: "space-y-4" do |f| %>
    <div>
      <%= f.label :password, "새 비밀번호", class: "block text-sm font-medium text-gray-700" %>
      <%= f.password_field :password, required: true, autocomplete: "new-password",
          class: "mt-1 block w-full rounded-md border-gray-300 shadow-sm" %>
    </div>

    <div>
      <%= f.label :password_confirmation, "비밀번호 확인", class: "block text-sm font-medium text-gray-700" %>
      <%= f.password_field :password_confirmation, required: true,
          class: "mt-1 block w-full rounded-md border-gray-300 shadow-sm" %>
    </div>

    <%= f.submit "비밀번호 변경", class: "w-full bg-blue-600 text-white rounded-md py-2 hover:bg-blue-700" %>
  <% end %>
</div>
```

### 6.4 Admin Users Views

```erb
<%# app/views/admin/users/index.html.erb %>
<div class="flex justify-between items-center mb-6">
  <h1 class="text-2xl font-bold">사용자 관리</h1>
  <%= link_to "새 사용자", new_admin_user_path, class: "bg-blue-600 text-white px-4 py-2 rounded" %>
</div>

<table class="min-w-full bg-white rounded-lg shadow">
  <thead class="bg-gray-50">
    <tr>
      <th class="px-6 py-3 text-left">이름</th>
      <th class="px-6 py-3 text-left">이메일</th>
      <th class="px-6 py-3 text-left">역할</th>
      <th class="px-6 py-3 text-left">관리</th>
    </tr>
  </thead>
  <tbody>
    <% @users.each do |user| %>
      <tr class="border-t">
        <td class="px-6 py-4"><%= user.name %></td>
        <td class="px-6 py-4"><%= user.email_address %></td>
        <td class="px-6 py-4"><%= user.role %></td>
        <td class="px-6 py-4">
          <%= link_to "보기", admin_user_path(user) %>
          <%= link_to "수정", edit_admin_user_path(user) %>
        </td>
      </tr>
    <% end %>
  </tbody>
</table>
```

```erb
<%# app/views/admin/users/show.html.erb %>
<div class="max-w-2xl mx-auto bg-white rounded-lg shadow p-8">
  <h1 class="text-2xl font-bold mb-6"><%= @user.name %></h1>

  <dl class="space-y-4">
    <div><dt class="text-sm text-gray-500">이메일</dt><dd><%= @user.email_address %></dd></div>
    <div><dt class="text-sm text-gray-500">역할</dt><dd><%= @user.role %></dd></div>
    <div><dt class="text-sm text-gray-500">생성일</dt><dd><%= @user.created_at.strftime("%Y-%m-%d") %></dd></div>
  </dl>

  <div class="mt-6 flex gap-4">
    <%= link_to "수정", edit_admin_user_path(@user), class: "bg-blue-600 text-white px-4 py-2 rounded" %>
    <%= link_to "목록", admin_users_path, class: "text-gray-600" %>
  </div>
</div>
```

```erb
<%# app/views/admin/users/_form.html.erb %>
<%= form_with model: [:admin, user], class: "space-y-4" do |f| %>
  <div>
    <%= f.label :name, "이름", class: "block text-sm font-medium text-gray-700" %>
    <%= f.text_field :name, required: true, class: "mt-1 block w-full rounded-md border-gray-300 shadow-sm" %>
  </div>

  <div>
    <%= f.label :email_address, "이메일", class: "block text-sm font-medium text-gray-700" %>
    <%= f.email_field :email_address, required: true, class: "mt-1 block w-full rounded-md border-gray-300 shadow-sm" %>
  </div>

  <div>
    <%= f.label :role, "역할", class: "block text-sm font-medium text-gray-700" %>
    <%= f.select :role, [["관리자", "admin"], ["운영자", "operator"], ["봉사자", "member"]],
        {}, class: "mt-1 block w-full rounded-md border-gray-300 shadow-sm" %>
  </div>

  <div>
    <%= f.label :password, "비밀번호#{user.new_record? ? '' : ' (변경 시에만 입력)'}", class: "block text-sm font-medium text-gray-700" %>
    <%= f.password_field :password, required: user.new_record?, class: "mt-1 block w-full rounded-md border-gray-300 shadow-sm" %>
  </div>

  <div>
    <%= f.label :password_confirmation, "비밀번호 확인", class: "block text-sm font-medium text-gray-700" %>
    <%= f.password_field :password_confirmation, class: "mt-1 block w-full rounded-md border-gray-300 shadow-sm" %>
  </div>

  <%= f.submit user.new_record? ? "생성" : "수정", class: "bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700" %>
<% end %>
```

```erb
<%# app/views/admin/users/new.html.erb %>
<div class="max-w-md mx-auto bg-white rounded-lg shadow p-8">
  <h1 class="text-xl font-bold mb-6">새 사용자 생성</h1>
  <%= render "form", user: @user %>
</div>
```

```erb
<%# app/views/admin/users/edit.html.erb %>
<div class="max-w-md mx-auto bg-white rounded-lg shadow p-8">
  <h1 class="text-xl font-bold mb-6">사용자 수정: <%= @user.name %></h1>
  <%= render "form", user: @user %>
</div>
```

### 6.5 Dashboard Page

```erb
<%# app/views/dashboard/index.html.erb %>
<h1 class="text-2xl font-bold mb-6">대시보드</h1>
<p class="text-gray-600">안녕하세요, <%= Current.user.name %>님. (<%= Current.user.role %>)</p>

<div class="grid grid-cols-1 md:grid-cols-3 gap-6 mt-8">
  <% if Current.user.admin? %>
    <div class="bg-white rounded-lg shadow p-6">
      <h3 class="font-bold text-gray-700">사용자 관리</h3>
      <%= link_to "사용자 목록", admin_users_path, class: "text-blue-600" %>
    </div>
  <% end %>

  <div class="bg-white rounded-lg shadow p-6">
    <h3 class="font-bold text-gray-700">내 정보</h3>
    <%= link_to "비밀번호 변경", edit_password_path, class: "text-blue-600" %>
  </div>
</div>
```

### 6.6 Navigation Partial

```erb
<%# app/views/layouts/_navbar.html.erb %>
<nav class="bg-white shadow">
  <div class="container mx-auto px-4">
    <div class="flex justify-between items-center h-16">
      <div class="flex items-center space-x-8">
        <%= link_to "성단 매니저", root_path, class: "text-xl font-bold text-blue-600" %>
        <% if Current.user&.admin? %>
          <%= link_to "사용자 관리", admin_users_path, class: "text-gray-600 hover:text-gray-900" %>
        <% end %>
      </div>

      <div class="flex items-center space-x-4">
        <span class="text-sm text-gray-600"><%= Current.user&.name %> (<%= Current.user&.role %>)</span>
        <%= link_to "비밀번호 변경", edit_password_path, class: "text-sm text-gray-600 hover:text-gray-900" %>
        <%= button_to "로그아웃", session_path, method: :delete, class: "text-sm text-red-600 hover:text-red-800" %>
      </div>
    </div>
  </div>
</nav>
```

---

## 7. Test Plan

### 7.1 Request Specs

```ruby
# spec/requests/sessions_spec.rb
RSpec.describe "Sessions" do
  let(:parish) { create(:parish) }
  let(:user) { create(:user, parish: parish, password: "password123") }

  describe "GET /session/new" do
    it "renders login page" do
      get new_session_path
      expect(response).to have_http_status(:ok)
    end
  end

  describe "POST /session" do
    it "logs in with valid credentials" do
      post session_path, params: { email_address: user.email_address, password: "password123" }
      expect(response).to redirect_to(root_path)
    end

    it "rejects invalid credentials" do
      post session_path, params: { email_address: user.email_address, password: "wrong" }
      expect(response).to redirect_to(new_session_path)
    end
  end

  describe "DELETE /session" do
    it "logs out the user" do
      post session_path, params: { email_address: user.email_address, password: "password123" }
      delete session_path
      expect(response).to redirect_to(new_session_path)
    end
  end
end

# spec/requests/passwords_spec.rb
RSpec.describe "Passwords" do
  let(:parish) { create(:parish) }
  let(:user) { create(:user, parish: parish, password: "password123") }

  before { sign_in(user) }

  describe "PATCH /password" do
    it "changes password with valid params" do
      patch password_path, params: { user: { password: "newpassword", password_confirmation: "newpassword" } }
      expect(response).to redirect_to(root_path)
    end
  end
end

# spec/requests/admin/users_spec.rb
RSpec.describe "Admin::Users" do
  let(:parish) { create(:parish) }
  let(:admin) { create(:user, :admin, parish: parish) }
  let(:member_user) { create(:user, :member_role, parish: parish) }

  describe "as admin" do
    before { sign_in(admin) }

    it "GET /admin/users returns success" do
      get admin_users_path
      expect(response).to have_http_status(:ok)
    end

    it "POST /admin/users creates a user" do
      expect {
        post admin_users_path, params: { user: { name: "New", email_address: "new@test.com", role: "member", password: "password123", password_confirmation: "password123" } }
      }.to change(User, :count).by(1)
    end
  end

  describe "as member" do
    before { sign_in(member_user) }

    it "GET /admin/users is forbidden" do
      get admin_users_path
      expect(response).to redirect_to(root_path)
    end
  end
end
```

### 7.2 Policy Specs

```ruby
# spec/policies/user_policy_spec.rb
RSpec.describe UserPolicy do
  let(:parish) { create(:parish) }
  let(:admin) { create(:user, :admin, parish: parish) }
  let(:operator) { create(:user, :operator, parish: parish) }
  let(:member_user) { create(:user, :member_role, parish: parish) }
  let(:other_user) { create(:user, :member_role, parish: parish) }

  subject { described_class }

  permissions :index? do
    it "grants access to admin" do
      expect(subject).to permit(admin, User)
    end
    it "denies access to operator" do
      expect(subject).not_to permit(operator, User)
    end
    it "denies access to member" do
      expect(subject).not_to permit(member_user, User)
    end
  end

  permissions :show? do
    it "grants access to admin for any user" do
      expect(subject).to permit(admin, other_user)
    end
    it "grants access to member for self" do
      expect(subject).to permit(member_user, member_user)
    end
    it "denies access to member for other user" do
      expect(subject).not_to permit(member_user, other_user)
    end
  end

  permissions :create?, :update? do
    it "grants access to admin" do
      expect(subject).to permit(admin, User)
    end
    it "denies access to operator" do
      expect(subject).not_to permit(operator, User)
    end
  end

  permissions :destroy? do
    it "grants admin access for other users" do
      expect(subject).to permit(admin, other_user)
    end
    it "denies admin from deleting self" do
      expect(subject).not_to permit(admin, admin)
    end
  end
end

# spec/policies/member_policy_spec.rb
RSpec.describe MemberPolicy do
  let(:parish) { create(:parish) }
  let(:admin) { create(:user, :admin, parish: parish) }
  let(:operator) { create(:user, :operator, parish: parish) }
  let(:member_user) { create(:user, :member_role, parish: parish) }
  let(:member_record) { create(:member, parish: parish, user: member_user) }
  let(:other_member) { create(:member, parish: parish) }

  subject { described_class }

  permissions :index? do
    it "grants access to admin and operator" do
      expect(subject).to permit(admin, Member)
      expect(subject).to permit(operator, Member)
    end
    it "denies access to member" do
      expect(subject).not_to permit(member_user, Member)
    end
  end

  permissions :show? do
    it "grants member access to own record" do
      expect(subject).to permit(member_user, member_record)
    end
    it "denies member access to other record" do
      expect(subject).not_to permit(member_user, other_member)
    end
  end
end
```

### 7.3 Test Support Helper

```ruby
# spec/support/authentication.rb
module AuthenticationHelper
  def sign_in(user)
    post session_path, params: {
      email_address: user.email_address,
      password: "password123"
    }
  end
end

RSpec.configure do |config|
  config.include AuthenticationHelper, type: :request
end
```

### 7.4 Test Coverage Matrix

| Spec File | Type | Tests |
|-----------|------|:---:|
| spec/requests/sessions_spec.rb | Request | 4 |
| spec/requests/passwords_spec.rb | Request | 2 |
| spec/requests/admin/users_spec.rb | Request | 6 |
| spec/requests/dashboard_spec.rb | Request | 2 |
| spec/policies/user_policy_spec.rb | Policy | 8 |
| spec/policies/member_policy_spec.rb | Policy | 6 |
| spec/policies/application_policy_spec.rb | Policy | 3 |
| **Total** | | **~31** |

---

## 8. Implementation Order

### 8.1 Step-by-step Checklist

```
Phase A: 인증 기반 (Core Authentication)
  1. [ ] Current 모델에 :session attribute 추가
  2. [ ] app/controllers/concerns/authentication.rb 생성
  3. [ ] app/controllers/application_controller.rb 생성
  4. [ ] app/controllers/sessions_controller.rb 생성
  5. [ ] app/views/sessions/new.html.erb 생성
  6. [ ] config/routes.rb 생성

Phase B: 레이아웃 & 대시보드
  7. [ ] app/views/layouts/application.html.erb 생성
  8. [ ] app/views/layouts/_navbar.html.erb 생성
  9. [ ] app/controllers/dashboard_controller.rb 생성
  10. [ ] app/views/dashboard/index.html.erb 생성

Phase C: Pundit 정책
  11. [ ] app/policies/application_policy.rb 생성
  12. [ ] app/policies/user_policy.rb 생성
  13. [ ] app/policies/member_policy.rb 생성

Phase D: 관리자 기능
  14. [ ] app/controllers/admin/users_controller.rb 생성
  15. [ ] app/views/admin/users/index.html.erb 생성
  16. [ ] app/views/admin/users/show.html.erb 생성
  17. [ ] app/views/admin/users/_form.html.erb 생성
  18. [ ] app/views/admin/users/new.html.erb 생성
  19. [ ] app/views/admin/users/edit.html.erb 생성

Phase E: 비밀번호 변경
  20. [ ] app/controllers/passwords_controller.rb 생성
  21. [ ] app/views/passwords/edit.html.erb 생성

Phase F: 테스트
  22. [ ] spec/support/authentication.rb 생성
  23. [ ] spec/requests/sessions_spec.rb 생성
  24. [ ] spec/requests/passwords_spec.rb 생성
  25. [ ] spec/requests/admin/users_spec.rb 생성
  26. [ ] spec/requests/dashboard_spec.rb 생성
  27. [ ] spec/policies/application_policy_spec.rb 생성
  28. [ ] spec/policies/user_policy_spec.rb 생성
  29. [ ] spec/policies/member_policy_spec.rb 생성
```

---

## 9. Security Considerations

- [x] 비밀번호: bcrypt (has_secure_password), 최소 8자
- [x] 세션: signed cookie (httponly, same_site: :lax)
- [x] CSRF: Rails 기본 protect_from_forgery
- [x] Rate Limit: 로그인 시도 3분당 10회 제한
- [x] Pundit: after_action :verify_authorized로 정책 누락 방지
- [x] 자기 삭제 방지: admin이 자기 자신 삭제 불가
- [x] 감사로그: 로그인/로그아웃/비밀번호 변경 기록
- [ ] 비밀번호 재설정: P1 (이메일 발송 필요)
- [ ] 계정 잠금: P1 (로그인 실패 횟수 기반)

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | 2026-02-16 | Initial design document | CTO Lead (Architect) |
