# F06: Assignment Management Design

> **Feature**: F06-assignment
> **Version**: 1.0
> **Date**: 2026-02-16
> **Plan Reference**: `docs/01-plan/features/F06-assignment.plan.md`

---

## 1. Service Object

### 1.1 AssignmentRecommender (`app/services/assignment_recommender.rb`)

자격조건 + 가용성 + 배정 이력 기반 후보 추천 서비스.

```ruby
class AssignmentRecommender
  def initialize(event, role)
    @event = event
    @role = role
  end

  def candidates(limit: 10)
    members = eligible_members
    scored = members.map { |m| [m, score(m)] }
    scored.sort_by { |_, s| -s }.first(limit).map { |m, s| { member: m, score: s } }
  end

  private

  def eligible_members
    members = Member.active
    members = members.baptized if @role.requires_baptism
    members = members.confirmed if @role.requires_confirmation
    members = members.where.not(id: already_assigned_ids)
    members = members.where.not(id: blackout_member_ids)
    members
  end

  def already_assigned_ids
    @event.assignments.where.not(status: "canceled").pluck(:member_id)
  end

  def blackout_member_ids
    BlackoutPeriod.active_on(@event.date).pluck(:member_id)
  end

  def score(member)
    s = 100
    # 최근 30일 배정 횟수 (적을수록 높은 점수)
    recent_count = member.assignments
      .where(created_at: 30.days.ago..)
      .where.not(status: "canceled")
      .count
    s -= (recent_count * 10)
    # 가용성 규칙 매칭 보너스
    if member.availability_rules.exists?(day_of_week: @event.date.wday)
      s += 20
    end
    [s, 0].max
  end
end
```

---

## 2. Policy

### 2.1 AssignmentPolicy (`app/policies/assignment_policy.rb`)

```ruby
class AssignmentPolicy < ApplicationPolicy
  def create?
    operator_or_admin?
  end

  def destroy?
    operator_or_admin?
  end

  def recommend?
    operator_or_admin?
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      scope.all
    end
  end
end
```

---

## 3. Controller

### 3.1 AssignmentsController (`app/controllers/assignments_controller.rb`)

이벤트에 중첩된 배정 관리 컨트롤러.

```ruby
class AssignmentsController < ApplicationController
  before_action :set_event

  # POST /events/:event_id/assignments
  def create
    @assignment = @event.assignments.build(assignment_params)
    @assignment.assigned_by = Current.user
    @assignment.status = "pending"
    authorize @assignment

    if @assignment.save
      redirect_to event_path(@event), notice: "봉사자가 배정되었습니다."
    else
      redirect_to event_path(@event), alert: @assignment.errors.full_messages.join(", ")
    end
  end

  # DELETE /events/:event_id/assignments/:id
  def destroy
    @assignment = @event.assignments.find(params[:id])
    authorize @assignment
    @assignment.update!(status: "canceled")
    redirect_to event_path(@event), notice: "배정이 취소되었습니다."
  end

  # GET /events/:event_id/assignments/recommend
  def recommend
    authorize Assignment, :recommend?
    @role = Role.find(params[:role_id])
    recommender = AssignmentRecommender.new(@event, @role)
    @candidates = recommender.candidates
    render partial: "assignments/candidates", locals: { candidates: @candidates, event: @event, role: @role }
  end

  private

  def set_event
    @event = Event.find(params[:event_id])
  end

  def assignment_params
    params.require(:assignment).permit(:member_id, :role_id)
  end
end
```

---

## 4. Routes

```ruby
resources :events do
  collection do
    get :bulk_new
    post :bulk_create
    delete :destroy_recurring
  end
  resources :assignments, only: %i[create destroy] do
    collection do
      get :recommend
    end
  end
end
```

---

## 5. Views

### 5.1 Event show 업데이트 (`app/views/events/show.html.erb`)

배정 현황 섹션에 실제 배정자 목록 + 추가/취소/추천 기능 추가:

```erb
<!-- 기존 assignment_summary 테이블을 확장 -->
<div class="bg-white rounded-lg shadow p-8">
  <h2 class="text-lg font-bold mb-4">역할별 배정 관리</h2>
  <% @assignment_summary.each do |summary| %>
    <div class="border-b py-4 last:border-b-0">
      <div class="flex justify-between items-center mb-2">
        <h3 class="font-medium">
          <%= summary[:role].name %>
          <span class="text-sm text-gray-500">(<%= summary[:assigned] %>/<%= summary[:required] %>명)</span>
        </h3>
        <% if policy(Assignment.new).create? && summary[:assigned] < summary[:required] %>
          <%= link_to "추천", recommend_event_assignments_path(@event, role_id: summary[:role].id),
              class: "text-sm text-green-600 hover:text-green-800",
              data: { turbo_frame: "recommend_#{summary[:role].id}" } %>
        <% end %>
      </div>

      <!-- 배정된 봉사자 목록 -->
      <% @event.assignments.where(role_id: summary[:role].id).where.not(status: "canceled").includes(:member).each do |assignment| %>
        <div class="flex justify-between items-center py-1 pl-4">
          <span>
            <%= assignment.member.name %>
            <span class="text-xs px-2 py-0.5 rounded-full
              <%= case assignment.status
                  when 'accepted' then 'bg-green-100 text-green-800'
                  when 'declined' then 'bg-red-100 text-red-800'
                  when 'pending' then 'bg-yellow-100 text-yellow-800'
                  else 'bg-gray-100 text-gray-800'
                  end %>">
              <%= assignment.status %>
            </span>
          </span>
          <% if policy(assignment).destroy? %>
            <%= button_to "취소", event_assignment_path(@event, assignment),
                method: :delete, class: "text-xs text-red-600 hover:text-red-800",
                data: { turbo_confirm: "#{assignment.member.name} 배정을 취소하시겠습니까?" } %>
          <% end %>
        </div>
      <% end %>

      <!-- 수동 배정 폼 -->
      <% if policy(Assignment.new).create? && summary[:assigned] < summary[:required] %>
        <div class="mt-2 pl-4">
          <%= form_with url: event_assignments_path(@event), class: "flex items-end gap-2" do |f| %>
            <%= f.hidden_field :assignment, value: nil %>
            <input type="hidden" name="assignment[role_id]" value="<%= summary[:role].id %>">
            <div class="flex-1">
              <%= f.select "assignment[member_id]",
                  Member.active.order(:name).map { |m| [m.name, m.id] },
                  { prompt: "봉사자 선택..." },
                  class: "w-full rounded-md border-gray-300 shadow-sm text-sm" %>
            </div>
            <%= f.submit "배정", class: "bg-blue-600 text-white px-3 py-2 rounded text-sm hover:bg-blue-700 cursor-pointer" %>
          <% end %>
        </div>
      <% end %>

      <!-- 추천 후보 Turbo Frame -->
      <%= turbo_frame_tag "recommend_#{summary[:role].id}" %>
    </div>
  <% end %>

  <% if @assignment_summary.empty? %>
    <p class="text-gray-500">이 미사유형에 역할 템플릿이 설정되지 않았습니다.</p>
  <% end %>
</div>
```

### 5.2 Candidates partial (`app/views/assignments/_candidates.html.erb`)

```erb
<%= turbo_frame_tag "recommend_#{role.id}" do %>
  <div class="bg-green-50 rounded p-3 mt-2">
    <h4 class="text-sm font-medium text-green-800 mb-2">추천 후보 (<%= role.name %>)</h4>
    <% if candidates.any? %>
      <% candidates.each do |c| %>
        <div class="flex justify-between items-center py-1">
          <span class="text-sm">
            <%= c[:member].name %>
            <span class="text-xs text-gray-500">(점수: <%= c[:score] %>)</span>
          </span>
          <%= button_to "배정",
              event_assignments_path(event),
              params: { assignment: { member_id: c[:member].id, role_id: role.id } },
              class: "text-xs bg-green-600 text-white px-2 py-1 rounded hover:bg-green-700" %>
        </div>
      <% end %>
    <% else %>
      <p class="text-sm text-gray-500">추천 가능한 후보가 없습니다.</p>
    <% end %>
  </div>
<% end %>
```

---

## 6. Test Plan

### 6.1 Request Spec (`spec/requests/assignments_spec.rb`)

| # | Test | Expected |
|---|------|----------|
| 1 | admin: POST creates assignment | Assignment +1, status=pending |
| 2 | admin: POST sets assigned_by | Current.user 기록 |
| 3 | admin: POST duplicate member+role+event is rejected | 422, error |
| 4 | admin: DELETE cancels assignment | status → canceled |
| 5 | admin: GET recommend returns candidates | 200, partial |
| 6 | operator: POST creates assignment | Assignment +1 |
| 7 | operator: DELETE cancels assignment | status → canceled |
| 8 | member: POST is forbidden | redirect |
| 9 | member: DELETE is forbidden | redirect |

### 6.2 Policy Spec (`spec/policies/assignment_policy_spec.rb`)

| # | Test | Expected |
|---|------|----------|
| 1 | admin: permits create? | true |
| 2 | admin: permits destroy? | true |
| 3 | operator: permits create? | true |
| 4 | operator: permits destroy? | true |
| 5 | member: denies create? | false |
| 6 | member: denies destroy? | false |

### 6.3 Service Spec (`spec/services/assignment_recommender_spec.rb`)

| # | Test | Expected |
|---|------|----------|
| 1 | returns active members only | inactive 제외 |
| 2 | filters by baptism requirement | 비세례자 제외 |
| 3 | filters by confirmation requirement | 미견진자 제외 |
| 4 | excludes already assigned members | 이미 배정된 멤버 제외 |
| 5 | excludes blackout period members | 불가 기간 멤버 제외 |
| 6 | scores by recent assignment count | 최근 배정 적은 멤버 우선 |
| 7 | bonus for availability rule match | 가용성 매칭 보너스 |

**Total: 22 tests** (9 request + 6 policy + 7 service)

---

## 7. Implementation Checklist

### Phase A: Service (1 file)
- [ ] A1. `app/services/assignment_recommender.rb`

### Phase B: Policy (1 file)
- [ ] B1. `app/policies/assignment_policy.rb`

### Phase C: Controller (1 file)
- [ ] C1. `app/controllers/assignments_controller.rb`

### Phase D: Views (2 files)
- [ ] D1. `app/views/events/show.html.erb` — 배정 관리 섹션 교체
- [ ] D2. `app/views/assignments/_candidates.html.erb` — 추천 후보 partial

### Phase E: Routes (1 file 수정)
- [ ] E1. `config/routes.rb` — nested assignments under events

### Phase F: Tests (3 files)
- [ ] F1. `spec/requests/assignments_spec.rb`
- [ ] F2. `spec/policies/assignment_policy_spec.rb`
- [ ] F3. `spec/services/assignment_recommender_spec.rb`

**Total: 10 files** (4 new + 2 modified + 1 new partial + 3 test files)
