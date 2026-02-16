# F04: Role & Event Type Templates - Analysis Report

> **Analysis Type**: Gap Analysis (Design vs Implementation)
>
> **Project**: AltarServe Manager
> **Version**: 0.1.0
> **Analyst**: Gap Detector Agent
> **Date**: 2026-02-16
> **Design Doc**: [F04-roles.design.md](../02-design/features/F04-roles.design.md)

---

## 1. Analysis Overview

### 1.1 Analysis Purpose

Verify that the F04 implementation (Role CRUD, EventType CRUD, EventRoleRequirement template management) matches the design document across models, controllers, policies, views, routes, and tests.

### 1.2 Analysis Scope

- **Design Document**: `docs/02-design/features/F04-roles.design.md`
- **Implementation Path**: `app/models/`, `app/controllers/admin/`, `app/policies/`, `app/views/admin/`, `config/routes.rb`, `spec/`
- **Analysis Date**: 2026-02-16
- **Files Compared**: 24 implementation files against design specifications

---

## 2. Gap Analysis (Design vs Implementation)

### 2.1 Model Comparison

| Item | Design | Implementation | Status |
|------|--------|----------------|--------|
| EventType: include ParishScoped | Yes | Yes | Match |
| EventType: include Auditable | Yes (added) | Yes | Match |
| EventType: has_many :event_role_requirements | dependent: :destroy | dependent: :destroy | Match |
| EventType: has_many :roles, through | Yes | Yes | Match |
| EventType: has_many :events | dependent: :restrict_with_error | dependent: :restrict_with_error | Match |
| EventType: validates :name | presence, uniqueness(scope: parish_id) | presence, uniqueness(scope: parish_id) | Match |
| EventType: scope :active | where(active: true) | where(active: true) | Match |
| EventType: scope :ordered | order(:name) | order(:name) | Match |
| EventType: total_required_count | sum(:required_count) | sum(:required_count) | Match |
| Role: no changes | Unchanged | Unchanged | Match |
| EventRoleRequirement: no changes | Unchanged | Unchanged | Match |

**Model Score: 11/11 (100%)**

### 2.2 Controller Comparison

#### Admin::RolesController

| Action/Method | Design | Implementation | Status |
|---------------|--------|----------------|--------|
| before_action :set_role | only: show, edit, update, toggle_active | only: show, edit, update, toggle_active | Match |
| index | policy_scope(Role).ordered; authorize Role | Identical | Match |
| show | authorize @role; load event_role_requirements | Identical | Match |
| new | Role.new with parish_id, next_sort_order | Identical | Match |
| create | new, set parish_id, authorize, save/redirect | Identical | Match |
| edit | authorize @role | Identical | Match |
| update | authorize, update, redirect/render | Identical | Match |
| toggle_active | authorize :destroy?, update! active toggle | Identical | Match |
| set_role (private) | Role.find(params[:id]) | Identical | Match |
| role_params | 7 permitted params | Identical | Match |
| next_sort_order | (Role.maximum(:sort_order) or -1) + 1 | Identical | Match |

#### Admin::EventTypesController

| Action/Method | Design | Implementation | Status |
|---------------|--------|----------------|--------|
| before_action :set_event_type | only: show, edit, update, toggle_active | only: show, edit, update, toggle_active | Match |
| index | policy_scope(EventType).ordered; authorize | Identical | Match |
| show | authorize; load requirements with includes; available_roles | Identical | Match |
| new | EventType.new with parish_id | Identical | Match |
| create | new, set parish_id, authorize, save/redirect | Identical | Match |
| edit | authorize @event_type | Identical | Match |
| update | authorize, update, redirect/render | Identical | Match |
| toggle_active | authorize :destroy?, update! active toggle | Identical | Match |
| set_event_type (private) | EventType.find(params[:id]) | Identical | Match |
| event_type_params | name, description, default_time | Identical | Match |

#### Admin::EventRoleRequirementsController

| Action/Method | Design | Implementation | Status |
|---------------|--------|----------------|--------|
| before_action :set_event_type | All actions | All actions | Match |
| before_action :set_requirement | only: update, destroy | only: update, destroy | Match |
| create | build, authorize :create?, save/redirect | Identical | Match |
| update | authorize, update, redirect | Identical | Match |
| destroy | authorize, destroy, redirect | Identical | Match |
| set_event_type (private) | find by event_type_id | Identical | Match |
| set_requirement (private) | find scoped to event_type | Identical | Match |
| requirement_params | role_id, required_count | Identical | Match |

**Controller Score: 29/29 (100%)**

### 2.3 Policy Comparison

| Policy | Method | Design | Implementation | Status |
|--------|--------|--------|----------------|--------|
| RolePolicy | index? | operator_or_admin? | operator_or_admin? | Match |
| RolePolicy | show? | operator_or_admin? | operator_or_admin? | Match |
| RolePolicy | create? | admin? | admin? | Match |
| RolePolicy | update? | admin? | admin? | Match |
| RolePolicy | destroy? | admin? | admin? | Match |
| RolePolicy | Scope#resolve | scope.all | scope.all | Match |
| EventTypePolicy | index? | operator_or_admin? | operator_or_admin? | Match |
| EventTypePolicy | show? | operator_or_admin? | operator_or_admin? | Match |
| EventTypePolicy | create? | admin? | admin? | Match |
| EventTypePolicy | update? | admin? | admin? | Match |
| EventTypePolicy | destroy? | admin? | admin? | Match |
| EventTypePolicy | Scope#resolve | scope.all | scope.all | Match |
| EventRoleRequirementPolicy | create? | admin? | admin? | Match |
| EventRoleRequirementPolicy | update? | admin? | admin? | Match |
| EventRoleRequirementPolicy | destroy? | admin? | admin? | Match |

**Policy Score: 15/15 (100%)**

### 2.4 Routes Comparison

| Route | Design | Implementation | Status |
|-------|--------|----------------|--------|
| admin/roles (resourceful) | resources :roles | resources :roles | Match |
| admin/roles/:id/toggle_active | member { patch :toggle_active } | member { patch :toggle_active } | Match |
| admin/event_types (resourceful) | resources :event_types | resources :event_types | Match |
| admin/event_types/:id/toggle_active | member { patch :toggle_active } | member { patch :toggle_active } | Match |
| nested event_role_requirements | only: create, update, destroy | only: create, update, destroy | Match |

**Routes Score: 5/5 (100%)**

### 2.5 View Comparison

#### Role Views

| View | Design Element | Implementation | Status |
|------|---------------|----------------|--------|
| index: page title | "역할 관리" | "역할 관리" | Match |
| index: new button (policy-gated) | policy(Role).create? | policy(Role).create? | Match |
| index: table columns | 순서, 역할명, 자격조건, 상태, 관리 | 순서, 역할명, 자격조건, 상태, 관리 | Match |
| index: qualification display | 세례/견진/나이 | 세례/견진/나이 | Match |
| index: active/inactive badge | text-green-600/text-red-600 | text-green-600/text-red-600 | Match |
| show: role name + status badge | name + rounded-full badge | Identical | Match |
| show: detail fields | 설명, 정렬순서, 최대인원, 자격조건 | Identical | Match |
| show: event types list | event_role_requirements with links | Identical | Match |
| show: edit/toggle/list buttons | policy-gated | Identical | Match |
| _form: fields | name, sort_order, max_members, min_age, description | Identical | Match |
| _form: checkboxes | requires_baptism, requires_confirmation | Identical | Match |
| _form: error display | errors.full_messages | Identical | Match |
| new: heading | "새 역할 등록" | "새 역할 등록" | Match |
| edit: heading | "역할 수정: {name}" | "역할 수정: {name}" | Match |

#### EventType Views

| View | Design Element | Implementation | Status |
|------|---------------|----------------|--------|
| index: page title | "미사유형 관리" | "미사유형 관리" | Match |
| index: new button (policy-gated) | policy(EventType).create? | policy(EventType).create? | Match |
| index: table columns | 미사유형, 기본시간, 필요역할, 상태, 관리 | Identical | Match |
| index: total_required_count display | et.total_required_count + "명" | Identical | Match |
| show: event type name + status badge | name + rounded-full badge | Identical | Match |
| show: detail fields | 설명, 기본시간 | Identical | Match |
| show: edit/toggle/list buttons | policy-gated | Identical | Match |
| show: role template section title | "역할 템플릿 (총 N명)" | Identical | Match |
| show: requirements table | 역할, 필요인원, 관리 columns | Identical | Match |
| show: inline edit form | form_with for required_count update | Identical | Match |
| show: delete with turbo_confirm | button_to with confirmation dialog | Identical | Match |
| show: add role form | select + required_count + submit | Identical | Match |
| show: empty state | "아직 등록된 역할이 없습니다." | Identical | Match |
| _form: fields | name, default_time, description | Identical | Match |
| _form: error display | errors.full_messages | Identical | Match |
| new: heading | "새 미사유형 등록" | "새 미사유형 등록" | Match |
| edit: heading | "미사유형 수정: {name}" | "미사유형 수정: {name}" | Match |

**View Score: 31/31 (100%)**

### 2.6 Navigation & Dashboard Comparison

| Item | Design | Implementation | Status |
|------|--------|----------------|--------|
| Navbar: "역할" link (admin-only) | admin_roles_path | admin_roles_path | Match |
| Navbar: "미사유형" link (admin-only) | admin_event_types_path | admin_event_types_path | Match |
| Dashboard: "역할 관리" card (admin-only) | admin_roles_path link | admin_roles_path link | Match |
| Dashboard: "미사유형 관리" card (admin-only) | admin_event_types_path link | admin_event_types_path link | Match |

**Navigation Score: 4/4 (100%)**

### 2.7 Test Comparison

#### Request Specs: Admin::Roles (spec/requests/admin/roles_spec.rb)

| Test Case | Design | Implementation | Status |
|-----------|--------|----------------|--------|
| admin: GET index returns success with role name | Yes | Yes | Match |
| admin: GET show displays role | Yes | Yes | Match |
| admin: GET new renders form | Yes | Yes | Match |
| admin: POST create creates role | Yes | Yes | Match |
| admin: PATCH update changes role | Yes | Yes | Match |
| admin: PATCH toggle_active toggles status | Yes | Yes (+ precondition assert) | Match |
| admin: show event types requiring this role | No | Yes | Added |
| operator: GET index succeeds | Yes | Yes | Match |
| operator: GET show succeeds | Yes | Yes | Match |
| operator: POST create is forbidden | Yes | Yes | Match |
| member: GET index is forbidden | Yes | Yes | Match |

Design: 9 tests. Implementation: 10 tests (+1 added).

#### Request Specs: Admin::EventTypes (spec/requests/admin/event_types_spec.rb)

| Test Case | Design | Implementation | Status |
|-----------|--------|----------------|--------|
| admin: GET index returns success with name | Yes | Yes | Match |
| admin: GET show displays event type | Yes | Yes (+ name assertion) | Match |
| admin: GET new renders form | No | Yes | Added |
| admin: POST create creates event type | Yes | Yes | Match |
| admin: PATCH update changes event type | Yes | Yes | Match |
| admin: PATCH toggle_active toggles status | Yes | Yes (+ precondition assert) | Match |
| admin: POST creates event role requirement | Yes | Yes | Match |
| admin: PATCH updates event role requirement | Yes | Yes | Match |
| admin: DELETE removes event role requirement | Yes | Yes | Match |
| admin: shows total required count on index | No | Yes | Added |
| operator: GET index succeeds | Yes | Yes | Match |
| operator: POST is forbidden | Yes | Yes | Match |
| operator: POST event_role_requirement is forbidden | No | Yes | Added |
| member: GET index is forbidden | Yes | Yes | Match |

Design: 10 tests. Implementation: 13 tests (+3 added).

#### Policy Specs: RolePolicy (spec/policies/role_policy_spec.rb)

| Test Case | Design | Implementation | Status |
|-----------|--------|----------------|--------|
| index?, show?: permits admin | Yes | Yes | Match |
| index?, show?: permits operator | Yes | Yes | Match |
| index?, show?: denies member | Yes | Yes | Match |
| create?, update?, destroy?: permits admin | Yes | Yes | Match |
| create?, update?, destroy?: denies operator | Yes | Yes | Match |
| create?, update?, destroy?: denies member | Yes | Yes | Match |

Design: 6 tests. Implementation: 6 tests. Exact match.

#### Policy Specs: EventTypePolicy (spec/policies/event_type_policy_spec.rb)

| Test Case | Design | Implementation | Status |
|-----------|--------|----------------|--------|
| index?, show?: permits admin | Yes | Yes | Match |
| index?, show?: permits operator | Yes | Yes | Match |
| index?, show?: denies member | Yes | Yes | Match |
| create?, update?, destroy?: permits admin | Yes | Yes | Match |
| create?, update?, destroy?: denies operator | Yes | Yes | Match |
| create?, update?, destroy?: denies member | Yes | Yes | Match |

Design: 6 tests. Implementation: 6 tests. Exact match.

#### Test Count Summary

| Spec File | Design Count | Implementation Count | Delta |
|-----------|:---:|:---:|:---:|
| spec/requests/admin/roles_spec.rb | 9 | 10 | +1 |
| spec/requests/admin/event_types_spec.rb | 10 | 13 | +3 |
| spec/policies/role_policy_spec.rb | 6 | 6 | 0 |
| spec/policies/event_type_policy_spec.rb | 6 | 6 | 0 |
| **Total** | **31** | **35** | **+4** |

Implementation has 113% of designed test count. All additional tests are improvements.

**Test Score: 31/31 designed tests implemented (100%) + 4 bonus tests**

### 2.8 Minor Assertion Style Differences

| Item | Design | Implementation | Impact |
|------|--------|----------------|--------|
| Operator forbidden assertion | `have_http_status(:forbidden).or redirect_to(root_path)` | `redirect_to(root_path)` | None (stricter) |
| Member forbidden assertion | `have_http_status(:forbidden).or redirect_to(root_path)` | `redirect_to(root_path)` | None (stricter) |
| toggle_active test | No precondition check | Adds `expect(role.active).to be true` before toggle | None (better) |

These are implementation improvements, not gaps. The implementation chose a more specific assertion (`redirect_to`) over the design's more permissive compound matcher. This is functionally superior because it verifies the exact redirect behavior configured in ApplicationController's Pundit denial handler.

---

## 3. Differences Summary

### 3.1 Missing Features (Design O, Implementation X)

**None found.**

### 3.2 Added Features (Design X, Implementation O)

| Item | Implementation Location | Description | Severity |
|------|------------------------|-------------|----------|
| "shows event types" test | spec/requests/admin/roles_spec.rb:46-52 | Verifies role show page displays related event types | Low (positive) |
| "new form" test | spec/requests/admin/event_types_spec.rb:24-27 | Verifies GET /admin/event_types/new renders form | Low (positive) |
| "total required count" test | spec/requests/admin/event_types_spec.rb:70-74 | Verifies total_required_count displayed on index | Low (positive) |
| "operator ERR forbidden" test | spec/requests/admin/event_types_spec.rb:90-94 | Verifies operator cannot create event_role_requirements | Low (positive) |

All additions are beneficial test coverage improvements.

### 3.3 Changed Features (Design != Implementation)

| Item | Design | Implementation | Impact |
|------|--------|----------------|--------|
| Forbidden assertion style | Compound matcher (status OR redirect) | Redirect only | None -- stricter is better |
| toggle_active test | No precondition | Adds precondition assertion | None -- more robust |

These are minor stylistic improvements, not functional discrepancies.

---

## 4. Architecture Compliance

### 4.1 Layer Structure

| Layer | Expected | Actual | Status |
|-------|----------|--------|--------|
| Models (Domain) | Role, EventType, EventRoleRequirement | Present | Match |
| Policies (Application) | RolePolicy, EventTypePolicy, EventRoleRequirementPolicy | Present | Match |
| Controllers (Presentation) | Admin::Roles, Admin::EventTypes, Admin::EventRoleRequirements | Present | Match |
| Views (Presentation) | 10 view files + 2 layout updates | Present | Match |

### 4.2 Concern Usage

| Concern | Design Spec | Implementation | Status |
|---------|------------|----------------|--------|
| ParishScoped on EventType | Yes | Yes | Match |
| Auditable on EventType | Added per design | Present | Match |
| Auditable on Role | Already present | Present | Match |
| Auditable on EventRoleRequirement | Already present | Present | Match |

**Architecture Score: 100%**

---

## 5. Convention Compliance

### 5.1 Naming Convention

| Category | Convention | Compliance | Violations |
|----------|-----------|:----------:|------------|
| Models | PascalCase | 100% | None |
| Controllers | PascalCase with Admin:: namespace | 100% | None |
| Policies | PascalCase + "Policy" suffix | 100% | None |
| Views | snake_case directories, snake_case.html.erb | 100% | None |
| Specs | snake_case_spec.rb | 100% | None |

### 5.2 Rails Convention Compliance

| Item | Status |
|------|--------|
| RESTful routes | Match |
| Admin namespace for privileged resources | Match |
| Nested resources for EventRoleRequirement | Match |
| Pundit authorize in every action | Match |
| policy_scope for index queries | Match |
| Strong parameters | Match |
| before_action for shared setup | Match |

**Convention Score: 100%**

---

## 6. Security Compliance

| Item | Design | Implementation | Status |
|------|--------|----------------|--------|
| RBAC: admin CRUD, operator read-only | Specified | Implemented | Match |
| RBAC: member denied | Specified | Implemented | Match |
| EventRoleRequirement: admin-only CRUD | Specified | Implemented | Match |
| ParishScoped data isolation | Specified | Implemented | Match |
| Auditable audit logging | Specified | Implemented | Match |
| Soft delete via active flag | Specified | Implemented | Match |
| dependent: restrict_with_error | Specified | Implemented | Match |
| turbo_confirm on delete | Specified | Implemented | Match |

**Security Score: 8/8 (100%)**

---

## 7. Overall Scores

| Category | Items | Matched | Score | Status |
|----------|:-----:|:-------:|:-----:|:------:|
| Model Comparison | 11 | 11 | 100% | PASS |
| Controller Comparison | 29 | 29 | 100% | PASS |
| Policy Comparison | 15 | 15 | 100% | PASS |
| Routes Comparison | 5 | 5 | 100% | PASS |
| View Comparison | 31 | 31 | 100% | PASS |
| Navigation & Dashboard | 4 | 4 | 100% | PASS |
| Test Comparison | 31 | 31 | 100% | PASS |
| Architecture Compliance | 8 | 8 | 100% | PASS |
| Convention Compliance | 12 | 12 | 100% | PASS |
| Security Compliance | 8 | 8 | 100% | PASS |
| **Total** | **154** | **154** | **100%** | **PASS** |

```
+---------------------------------------------+
|  Overall Match Rate: 100%                   |
+---------------------------------------------+
|  Designed Items:      154  (100% matched)   |
|  Missing (Design>Impl): 0  (0%)            |
|  Added (Impl>Design):   4  (bonus tests)   |
|  Changed:                0  (0 functional)  |
+---------------------------------------------+
```

---

## 8. Recommended Actions

### 8.1 Immediate Actions

None required. All design specifications are fully implemented.

### 8.2 Documentation Update (Optional)

| Priority | Item | Description |
|----------|------|-------------|
| Low | Update test count in design | Design doc Section 7.3 states 31 tests; implementation has 35. Consider updating the design matrix to reflect actual test coverage. |
| Low | Document assertion style choice | The implementation chose `redirect_to(root_path)` over the compound matcher. This could be noted as a deliberate convention decision. |

### 8.3 Future Considerations

| Item | Description |
|------|-------------|
| Navbar operator visibility | Design shows "역할" and "미사유형" links only for admin. Operators who have read access (index/show) cannot navigate via navbar. Consider adding operator-visible nav links with read-only context. |
| Dashboard operator cards | Same as above -- operator has access to roles/event_types index but no dashboard card to navigate there. |

---

## 9. Conclusion

The F04 implementation achieves a **100% match rate** against the design document. Every model change, controller action, policy rule, view element, route definition, and test case specified in the design has been implemented exactly as designed. The implementation also includes 4 additional tests beyond the design specification, improving overall coverage.

This is the highest match rate observed in the project to date (F01=96%, F02=96%, F03=97%, F04=100%).

---

## Related Documents

- Plan: [F04-roles.plan.md](../01-plan/features/F04-roles.plan.md)
- Design: [F04-roles.design.md](../02-design/features/F04-roles.design.md)

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | 2026-02-16 | Initial gap analysis | Gap Detector Agent |
