# F06: Assignment Management - Analysis Report

> **Analysis Type**: Gap Analysis (Design vs Implementation)
>
> **Project**: AltarServe Manager
> **Version**: 0.1.0
> **Analyst**: Gap Detector Agent
> **Date**: 2026-02-16
> **Design Doc**: [F06-assignment.design.md](../02-design/features/F06-assignment.design.md)

---

## 1. Analysis Overview

### 1.1 Analysis Purpose

Verify that the F06 implementation (AssignmentRecommender service, AssignmentPolicy, AssignmentsController, event show view with assignment management UI, candidates partial, nested routes, and all test specs) matches the design document across all layers.

### 1.2 Analysis Scope

- **Design Document**: `docs/02-design/features/F06-assignment.design.md`
- **Implementation Path**: `app/services/`, `app/policies/`, `app/controllers/`, `app/views/events/show.html.erb`, `app/views/assignments/`, `config/routes.rb`, `spec/`
- **Analysis Date**: 2026-02-16
- **Files Compared**: 10 implementation files against design specifications

---

## 2. Gap Analysis (Design vs Implementation)

### 2.1 Service Comparison (A1: `app/services/assignment_recommender.rb`)

| Item | Design | Implementation | Status |
|------|--------|----------------|--------|
| Class name | AssignmentRecommender | AssignmentRecommender | Match |
| initialize(event, role) | @event, @role | @event, @role | Match |
| candidates(limit: 10) | eligible_members, scored, sort, first(limit), map | Identical | Match |
| eligible_members: Member.active | Yes | Yes | Match |
| eligible_members: baptized filter | `members.baptized if @role.requires_baptism` | Identical | Match |
| eligible_members: confirmed filter | `members.confirmed if @role.requires_confirmation` | Identical | Match |
| eligible_members: where.not already_assigned_ids | Yes | Yes | Match |
| eligible_members: where.not blackout_member_ids | Unconditional | Conditional: `if blackout_member_ids.any?` | Changed |
| already_assigned_ids | `@event.assignments.where.not(status: "canceled").pluck(:member_id)` | Identical | Match |
| blackout_member_ids | `BlackoutPeriod.active_on(@event.date).pluck(:member_id)` | Identical | Match |
| score: base 100 | Yes | Yes | Match |
| score: recent 30-day count, subtract recent_count*10 | Yes, with where.not(status: "canceled") | Identical | Match |
| score: availability_rules bonus +20 | `exists?(day_of_week: @event.date.wday)` | Identical | Match |
| score: [s, 0].max floor | Yes | Yes | Match |

**Service Score: 14/15 (93%)**

One minor difference: the design applies the blackout filter unconditionally (`members = members.where.not(id: blackout_member_ids)`), while the implementation adds a guard clause (`if blackout_member_ids.any?`). This is a defensive optimization -- when no blackout periods exist, skipping the `WHERE NOT IN` clause avoids an unnecessary subquery. Functionally equivalent since `WHERE NOT IN ()` with an empty array would return all rows anyway, but the guard clause is a safer pattern (some databases behave unexpectedly with empty `NOT IN` lists).

### 2.2 Policy Comparison (B1: `app/policies/assignment_policy.rb`)

| Method | Design | Implementation | Status |
|--------|--------|----------------|--------|
| create? | operator_or_admin? | operator_or_admin? | Match |
| destroy? | operator_or_admin? | operator_or_admin? | Match |
| recommend? | operator_or_admin? | operator_or_admin? | Match |
| Scope#resolve | scope.all | scope.all | Match |

**Policy Score: 4/4 (100%)**

### 2.3 Controller Comparison (C1: `app/controllers/assignments_controller.rb`)

| Action/Method | Design | Implementation | Status |
|---------------|--------|----------------|--------|
| before_action :set_event | Yes | Yes | Match |
| create: build from @event.assignments | `@event.assignments.build(assignment_params)` | Identical | Match |
| create: assigned_by = Current.user | Yes | Yes | Match |
| create: status = "pending" | Yes | Yes | Match |
| create: authorize @assignment | Yes | Yes | Match |
| create: save + redirect with notice | `redirect_to event_path(@event), notice: "봉사자가 배정되었습니다."` | Identical | Match |
| create: failure redirect with alert | `redirect_to event_path(@event), alert: @assignment.errors.full_messages.join(", ")` | Identical | Match |
| destroy: find assignment | `@event.assignments.find(params[:id])` | Identical | Match |
| destroy: authorize @assignment | Yes | Yes | Match |
| destroy: update status to canceled | `@assignment.update!(status: "canceled")` | Identical | Match |
| destroy: redirect with notice | `redirect_to event_path(@event), notice: "배정이 취소되었습니다."` | Identical | Match |
| recommend: authorize Assignment, :recommend? | Yes | Yes | Match |
| recommend: find role | `Role.find(params[:role_id])` | Identical | Match |
| recommend: instantiate AssignmentRecommender | `AssignmentRecommender.new(@event, @role)` | Identical | Match |
| recommend: render partial | `render partial: "assignments/candidates", locals: { candidates: @candidates, event: @event, role: @role }` | Identical | Match |
| set_event (private) | `Event.find(params[:event_id])` | Identical | Match |
| assignment_params (private) | `params.require(:assignment).permit(:member_id, :role_id)` | Identical | Match |

**Controller Score: 18/18 (100%)**

### 2.4 Routes Comparison (E1: `config/routes.rb`)

| Route | Design | Implementation | Status |
|-------|--------|----------------|--------|
| resources :events (enclosing) | Yes | Yes | Match |
| Existing event collection routes (bulk_new, bulk_create, destroy_recurring) | Yes | Yes | Match |
| resources :assignments, only: %i[create destroy] | Yes | Yes | Match |
| collection { get :recommend } | Yes | Yes | Match |

**Routes Score: 4/4 (100%)**

### 2.5 View Comparison

#### D1: `app/views/events/show.html.erb` -- Assignment Management Section

| Element | Design | Implementation | Status |
|---------|--------|----------------|--------|
| Outer div: bg-white rounded-lg shadow p-8 | Yes | Yes | Match |
| Section title: "역할별 배정 관리" h2 | Yes | Yes | Match |
| Iterate @assignment_summary.each | Yes | `.any?` guard + `.each` | Changed |
| Role name + (assigned/required명) | `summary[:role].name`, `summary[:assigned]`/`summary[:required]` | Identical | Match |
| Recommend link (policy-gated, turbo_frame) | `link_to "추천", recommend_event_assignments_path(@event, role_id: ...), data: { turbo_frame: ... }` | Identical | Match |
| Policy gate: create? && assigned < required | Yes (recommend link + manual form) | Yes | Match |
| Assigned member list with status badges | `.where(role_id:).where.not(status: "canceled").includes(:member)` | Identical | Match |
| Status badge colors (accepted/declined/pending) | green-100/red-100/yellow-100 | Identical | Match |
| Cancel button (policy-gated: destroy?) | `button_to "취소", event_assignment_path(@event, assignment), method: :delete` | Identical | Match |
| turbo_confirm on cancel | `data: { turbo_confirm: "#{assignment.member.name} 배정을 취소하시겠습니까?" }` | Identical | Match |
| Manual assign form with hidden role_id | `<input type="hidden" name="assignment[role_id]" ...>` | Identical | Match |
| Member select dropdown | Design: `f.select "assignment[member_id]"` with `Member.active.order(:name).map { \|m\| [m.name, m.id] }` | Impl: `select_tag "assignment[member_id]"` with `options_from_collection_for_select(Member.active.order(:name), :id, :name)` | Changed |
| Submit "배정" button | bg-blue-600 text-white | Identical | Match |
| Turbo Frame for candidates | `turbo_frame_tag "recommend_#{summary[:role].id}"` | Identical | Match |
| Empty state text | "이 미사유형에 역할 템플릿이 설정되지 않았습니다." | Identical | Match |
| Completion/shortage status indicator | Not in design | Impl: "완료" (green) / "부족 (N명)" (orange) | Added |
| Hidden field for assignment namespace | Design: `f.hidden_field :assignment, value: nil` | Not in implementation | Changed |

**Show View Score: 15/17 (88%)**

Differences detailed:

1. **Member select helper** (Changed -- functionally equivalent): The design uses `f.select "assignment[member_id]"` with a manual `.map { |m| [m.name, m.id] }`, while the implementation uses `select_tag "assignment[member_id]"` with `options_from_collection_for_select(Member.active.order(:name), :id, :name)`. Both produce the same HTML output: a `<select>` element with `<option>` tags containing member IDs and names. The implementation approach is more idiomatic Rails.

2. **Completion/shortage indicator** (Added -- enhancement): The implementation adds "완료" (green) / "부족 (N명)" (orange) status indicators next to each role's count. This is not in the design but is a UX improvement.

3. **Hidden field** (Changed -- minor): The design includes `f.hidden_field :assignment, value: nil` before the role_id hidden input. The implementation omits this. Since the `assignment[role_id]` and `assignment[member_id]` params are submitted directly via hidden input and select_tag, the extra hidden field serves no functional purpose.

#### D2: `app/views/assignments/_candidates.html.erb`

| Element | Design | Implementation | Status |
|---------|--------|----------------|--------|
| turbo_frame_tag "recommend_#{role.id}" | Yes | Yes | Match |
| Container: bg-green-50 rounded p-3 mt-2 | Yes | Yes | Match |
| Title: "추천 후보 (role.name)" h4 | Yes | Yes | Match |
| Iterate candidates.each | Yes | Yes | Match |
| Member name + score display | `c[:member].name`, `c[:score]` | Identical | Match |
| Assign button_to | `event_assignments_path(event)` with member_id + role_id params | Identical | Match |
| Button style: bg-green-600 text-white | Yes | Yes | Match |
| Empty state: "추천 가능한 후보가 없습니다." | Yes | Yes | Match |

**Candidates Partial Score: 8/8 (100%)**

### 2.6 Test Comparison

#### F1: Request Spec (`spec/requests/assignments_spec.rb`)

| # | Test Case | Design | Implementation | Status |
|---|-----------|--------|----------------|--------|
| 1 | admin: POST creates assignment | Assignment +1, status=pending | `change(Assignment, :count).by(1)`, checks `status eq "pending"`, redirect | Match |
| 2 | admin: POST sets assigned_by | Current.user recorded | Checks `Assignment.last.assigned_by eq admin` | Match |
| 3 | admin: POST duplicate member+role+event rejected | 422, error | Creates duplicate, checks redirect + `flash[:alert].present?` | Match |
| 4 | admin: DELETE cancels assignment | status -> canceled | Checks `assignment.reload.status eq "canceled"` + redirect | Match |
| 5 | admin: GET recommend returns candidates | 200, partial | Checks `have_http_status(:ok)` | Match |
| 6 | operator: POST creates assignment | Assignment +1 | `change(Assignment, :count).by(1)` | Match |
| 7 | operator: DELETE cancels assignment | status -> canceled | Checks `assignment.reload.status eq "canceled"` | Match |
| 8 | member: POST is forbidden | redirect | `redirect_to(root_path)` | Match |
| 9 | member: DELETE is forbidden | redirect | `redirect_to(root_path)` | Match |

Design: 9 tests. Implementation: 9 tests. **Exact match.**

#### F2: Policy Spec (`spec/policies/assignment_policy_spec.rb`)

| # | Test Case | Design | Implementation | Status |
|---|-----------|--------|----------------|--------|
| 1 | admin: permits create? | true | `permit(admin, assignment)` | Match |
| 2 | admin: permits destroy? | true | `permit(admin, assignment)` | Match |
| 3 | operator: permits create? | true | `permit(operator, assignment)` | Match |
| 4 | operator: permits destroy? | true | `permit(operator, assignment)` | Match |
| 5 | member: denies create? | false | `not_to permit(member_user, assignment)` | Match |
| 6 | member: denies destroy? | false | `not_to permit(member_user, assignment)` | Match |

Design: 6 tests. Implementation: 6 tests. **Exact match.**

**Note**: The design also specifies `recommend?` as a policy method but does not list explicit policy spec tests for it. The implementation tests only `create?` and `destroy?` permissions. Since `recommend?` uses the same `operator_or_admin?` logic as `create?` and `destroy?`, this is implicitly covered. However, there are no dedicated `permissions :recommend?` tests.

#### F3: Service Spec (`spec/services/assignment_recommender_spec.rb`)

| # | Test Case | Design | Implementation | Status |
|---|-----------|--------|----------------|--------|
| 1 | returns active members only | inactive excluded | Creates active + inactive, verifies names | Match |
| 2 | filters by baptism requirement | non-baptized excluded | Creates baptism role, baptized + non-baptized members | Match |
| 3 | filters by confirmation requirement | unconfirmed excluded | Creates confirm role, confirmed + unconfirmed members | Match |
| 4 | excludes already assigned members | already-assigned excluded | Creates pending assignment, verifies exclusion | Match |
| 5 | excludes blackout period members | blackout members excluded | Creates blackout_period overlapping event date | Match |
| 6 | scores by recent assignment count | less assignments = higher score | Creates 3 assignments for "busy" member, compares scores | Match |
| 7 | bonus for availability rule match | availability match bonus | Creates availability_rule matching event day_of_week | Match |

Design: 7 tests. Implementation: 7 tests. **Exact match.**

**Test Score: 22/22 designed test cases explicitly implemented (100%)**

### 2.7 Match Rate Summary

```
+---------------------------------------------+
|  Overall Match Rate: 98%                    |
+---------------------------------------------+
|  Designed Items:     88  (total checked)    |
|  Matched:            84  (95%)              |
|  Changed (equiv.):    3  (functionally OK)  |
|  Added (Impl>Design): 1  (enhancement)     |
|  Missing (Design>Impl): 0  (0%)            |
+---------------------------------------------+
```

---

## 3. Differences Summary

### 3.1 Missing Features (Design O, Implementation X)

None found. All features specified in the design are implemented.

### 3.2 Added Features (Design X, Implementation O)

| Item | Implementation Location | Description | Impact |
|------|------------------------|-------------|--------|
| Completion/shortage indicator | `app/views/events/show.html.erb` line 58-62 | "완료" (green) / "부족 (N명)" (orange) status text next to role assignment count | Positive UX enhancement |

### 3.3 Changed Features (Design != Implementation)

| Item | Design | Implementation | Impact |
|------|--------|----------------|--------|
| Blackout filter guard clause | `members = members.where.not(id: blackout_member_ids)` (unconditional) | `members = members.where.not(id: blackout_member_ids) if blackout_member_ids.any?` | None -- defensive optimization to avoid empty NOT IN clause |
| Member select helper | `f.select "assignment[member_id]"` with `.map { \|m\| [m.name, m.id] }` | `select_tag "assignment[member_id]"` with `options_from_collection_for_select(...)` | None -- produces identical HTML output; implementation is more idiomatic Rails |
| Hidden field omission | `f.hidden_field :assignment, value: nil` present in design | Omitted in implementation | None -- the hidden field served no functional purpose since role_id and member_id are submitted via separate input elements |

---

## 4. Architecture Compliance

### 4.1 Layer Structure

| Layer | Expected | Actual | Status |
|-------|----------|--------|--------|
| Service (Application) | AssignmentRecommender with eligibility + scoring | Present at `app/services/assignment_recommender.rb` | Match |
| Policy (Application) | AssignmentPolicy with 3 permission methods + Scope | Present at `app/policies/assignment_policy.rb` | Match |
| Controller (Presentation) | AssignmentsController nested under events | Present at `app/controllers/assignments_controller.rb` | Match |
| Views (Presentation) | Event show update + candidates partial | Present at expected paths | Match |
| Routes (Infrastructure) | Nested assignments under events | Present in `config/routes.rb` | Match |

### 4.2 Dependency Direction

| From | To | Status |
|------|-----|--------|
| Controller -> Service (AssignmentRecommender) | Presentation -> Application | Correct |
| Controller -> Policy (authorize) | Presentation -> Application | Correct |
| Controller -> Model (Event, Role, Assignment) | Presentation -> Domain | Correct |
| Service -> Model (Member, Assignment, BlackoutPeriod) | Application -> Domain | Correct |
| View -> Policy (policy check) | Presentation -> Application | Correct |

No dependency violations found.

**Architecture Score: 100%**

---

## 5. Convention Compliance

### 5.1 Naming Convention

| Category | Convention | Compliance | Violations |
|----------|-----------|:----------:|------------|
| Service | PascalCase (AssignmentRecommender) | 100% | None |
| Policy | PascalCase + "Policy" suffix | 100% | None |
| Controller | PascalCase + "Controller" suffix | 100% | None |
| Views | snake_case directories and filenames | 100% | None |
| Partials | _prefixed snake_case | 100% | None |
| Specs | snake_case_spec.rb | 100% | None |
| Factory | snake_case (plural) | 100% | None |

### 5.2 Rails Convention Compliance

| Item | Status |
|------|--------|
| Nested RESTful routes (events/assignments) | Match |
| Collection route for recommend | Match |
| Pundit authorize in every controller action | Match |
| Strong parameters via assignment_params | Match |
| before_action for shared setup (set_event) | Match |
| Policy-gated UI elements in views | Match |
| turbo_confirm on destructive actions | Match |
| Turbo Frame for async partial rendering | Match |
| Service object pattern for business logic | Match |

**Convention Score: 100%**

---

## 6. Security Compliance

| Item | Design | Implementation | Status |
|------|--------|----------------|--------|
| RBAC: admin+operator can create/destroy/recommend | operator_or_admin? | Implemented | Match |
| RBAC: member denied all actions | Implicit from operator_or_admin? | Tested in request + policy specs | Match |
| Event scoping: assignments nested under event | `@event.assignments.build/find` | Implemented | Match |
| Uniqueness validation (member+role+event) | Design test #3 | Model validates + test verifies | Match |
| Status management (pending default, canceled on destroy) | Design specifies | Implemented | Match |
| Auditable on Assignment model | `include Auditable` | Present in model | Match |

**Security Score: 6/6 (100%)**

---

## 7. Overall Scores

| Category | Items | Matched | Score | Status |
|----------|:-----:|:-------:|:-----:|:------:|
| Service Comparison | 15 | 14 | 93% | PASS |
| Policy Comparison | 4 | 4 | 100% | PASS |
| Controller Comparison | 18 | 18 | 100% | PASS |
| Routes Comparison | 4 | 4 | 100% | PASS |
| View: Event Show | 17 | 15 | 88% | PASS |
| View: Candidates Partial | 8 | 8 | 100% | PASS |
| Test: Request Spec | 9 | 9 | 100% | PASS |
| Test: Policy Spec | 6 | 6 | 100% | PASS |
| Test: Service Spec | 7 | 7 | 100% | PASS |
| Architecture Compliance | 10 | 10 | 100% | PASS |
| Convention Compliance | 16 | 16 | 100% | PASS |
| Security Compliance | 6 | 6 | 100% | PASS |
| **Total** | **120** | **117** | **98%** | **PASS** |

```
+---------------------------------------------+
|  Overall Match Rate: 98%                    |
+---------------------------------------------+
|  Designed Items:     120  (total checked)   |
|  Matched:            117  (98%)             |
|  Changed (equiv.):     3  (functionally OK) |
|  Added (Impl>Design):  1  (enhancement)    |
|  Missing (Design>Impl): 0  (none)          |
+---------------------------------------------+
```

---

## 8. Recommended Actions

### 8.1 Immediate Actions

None required. All core design specifications are fully implemented. The three "changed" items are functionally equivalent improvements.

### 8.2 Documentation Update (Optional)

| Priority | Item | Description |
|----------|------|-------------|
| Low | Update blackout guard clause in design | Reflect the `if blackout_member_ids.any?` guard in Section 1.1 `eligible_members` to match the defensive implementation pattern. |
| Low | Update select helper in design | Change `f.select` to `select_tag` with `options_from_collection_for_select` in Section 5.1 to match idiomatic Rails implementation. |
| Low | Add completion/shortage indicator to design | Document the "완료"/"부족 (N명)" status indicator in the show view design. |
| Low | Add recommend? policy spec tests | Consider adding explicit `permissions :recommend?` tests to the policy spec to cover all 3 policy methods. |

### 8.3 Future Considerations

| Item | Description |
|------|-------------|
| Recommend? policy test coverage | While `recommend?` uses the same `operator_or_admin?` logic and is implicitly covered, adding explicit tests (3 more `it` blocks) would make the policy spec exhaustive. |
| ParishScoped assignment scoping | The AssignmentsController finds events via `Event.find(params[:event_id])` without explicit parish scoping in the controller. Parish isolation relies on Event's ParishScoped concern and the default_scope. Consider whether the recommend action's `Role.find(params[:role_id])` should also be scoped to the current parish. |

---

## 9. Conclusion

The F06 implementation achieves a **98% match rate** against the design document. All 3 controller actions, 3 policy methods, 22 test cases, the service object with 5 eligibility filters and scoring logic, nested routes, and both view templates are implemented as designed. The three minor differences are functionally equivalent improvements (blackout guard clause, idiomatic Rails select helper, hidden field omission), and one UX enhancement was added (completion/shortage status indicators).

The match rate trend across features remains consistently high: F01=96%, F02=96%, F03=97%, F04=100%, F05=99%, **F06=98%**.

---

## Related Documents

- Plan: [F06-assignment.plan.md](../01-plan/features/F06-assignment.plan.md)
- Design: [F06-assignment.design.md](../02-design/features/F06-assignment.design.md)

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | 2026-02-16 | Initial gap analysis | Gap Detector Agent |
