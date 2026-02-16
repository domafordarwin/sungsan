# F04: Role & Event Type Templates Planning Document

> **Summary**: 역할(Role) 관리 + 미사유형(EventType) 관리 + 템플릿(EventRoleRequirement) 구성 UI 구현
>
> **Project**: AltarServe Manager (성단 매니저)
> **Version**: 0.1.0
> **Author**: CTO Lead
> **Date**: 2026-02-16
> **Status**: Draft
> **Depends On**: F01-bootstrap (archived, 96%), F02-auth (archived, 98%), F03-members (archived, 97%)

---

## 1. Overview

### 1.1 Purpose

전례 봉사 역할(Role)과 미사/행사 유형(EventType)을 정의하고, 각 미사유형에 필요한 역할별 인원수 템플릿(EventRoleRequirement)을 구성하는 관리 UI를 구현합니다. F01에서 생성한 Role, EventType, EventRoleRequirement, Qualification 모델을 기반으로, 관리자/운영자가 역할 체계와 미사유형별 인원 배치 템플릿을 설정할 수 있도록 합니다.

### 1.2 Background

- F01에서 Role, EventType, EventRoleRequirement, Qualification, MemberQualification 모델 이미 생성됨
- F02에서 Authentication, Pundit RBAC 이미 구현됨
- MVP 요구사항 FR-03: "역할 정의 및 미사유형별 템플릿" 해당
- 역할 예시: 십자가봉사, 초봉사, 향봉사, 성체봉사, 종봉사, 독서봉사 등
- 미사유형 예시: 주일미사(1차~4차), 평일미사, 주일학교미사, 대축일미사, 특별전례 등
- 각 미사유형별로 필요한 역할과 인원수가 다르므로 템플릿으로 관리

### 1.3 Related Documents

- MVP Plan: `docs/01-plan/features/altarserve-mvp.plan.md` (FR-03)
- F01 Bootstrap: `docs/archive/2026-02/F01-bootstrap/`
- F02 Auth: `docs/archive/2026-02/F02-auth/`
- F03 Members: `docs/archive/2026-02/F03-members/`
- Conventions: `docs/01-plan/03-conventions.md`

---

## 2. Scope

### 2.1 In Scope

- [x] 역할(Role) CRUD (admin: 전체, operator: 조회)
- [x] 역할 정렬 (sort_order 기반)
- [x] 역할 자격조건 설정 (requires_baptism, requires_confirmation, min_age)
- [x] 역할 활성화/비활성화
- [x] 미사유형(EventType) CRUD (admin: 전체, operator: 조회)
- [x] 미사유형 기본시간 설정 (default_time)
- [x] 미사유형 활성화/비활성화
- [x] 미사유형별 역할 템플릿(EventRoleRequirement) 관리
- [x] 템플릿: 역할 추가/제거, 필요인원수(required_count) 설정
- [x] 자격(Qualification) 목록 조회 (참조용)
- [x] 감사로그 자동 기록 (Auditable concern 활용)
- [x] ParishScoped 적용 (본당별 독립 역할/미사유형)

### 2.2 Out of Scope

- 자격(Qualification) CRUD 관리 UI - P1 (현재는 seed/console로 관리)
- MemberQualification 연동 UI - P1 (봉사자별 자격 부여/조회)
- 역할별 봉사자 배정 현황 - F06 (Assignment)
- 미사유형별 일정 생성 - F05 (Events)
- 역할 간 우선순위/계층 관리 - P2

---

## 3. Requirements

### 3.1 Functional Requirements

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-01 | 역할 목록 조회 (정렬순) | Critical | Pending |
| FR-02 | 역할 등록 (admin) | Critical | Pending |
| FR-03 | 역할 수정 (admin) | High | Pending |
| FR-04 | 역할 비활성화/활성화 (admin, soft delete) | High | Pending |
| FR-05 | 역할 자격조건 설정 (세례, 견진, 최소연령) | High | Pending |
| FR-06 | 미사유형 목록 조회 | Critical | Pending |
| FR-07 | 미사유형 등록 (admin) | Critical | Pending |
| FR-08 | 미사유형 수정 (admin) | High | Pending |
| FR-09 | 미사유형 비활성화/활성화 (admin) | High | Pending |
| FR-10 | 미사유형별 역할 템플릿 관리 (역할 추가/제거, 인원수 설정) | Critical | Pending |
| FR-11 | 템플릿 요약 표시 (총 필요 인원수, 역할별 인원) | Medium | Pending |
| FR-12 | 감사로그 자동 기록 | High | Pending (Auditable) |
| FR-13 | ParishScoped 적용 | High | Pending (ParishScoped) |
| FR-14 | 역할/미사유형 정렬 관리 | Medium | Pending |

### 3.2 Non-Functional Requirements

| Category | Criteria | Measurement Method |
|----------|----------|-------------------|
| Performance | 목록 조회 < 100ms | Rails logs |
| Security | RBAC 정책 100% 적용 (admin: CRUD, operator: 조회) | Policy spec |
| Security | ParishScoped 교차 접근 차단 | Request spec |
| Usability | 템플릿 구성 직관적 (Turbo Frame 활용) | Manual test |
| Usability | 모바일 반응형 | Visual test |

---

## 4. Success Criteria

### 4.1 Definition of Done

- [ ] RolesController CRUD 완료
- [ ] EventTypesController CRUD 완료
- [ ] EventRoleRequirement 템플릿 관리 완료
- [ ] RolePolicy, EventTypePolicy RBAC 테스트 통과
- [ ] Request spec 작성 (roles, event_types)
- [ ] Policy spec 작성 (role_policy, event_type_policy)
- [ ] RSpec 테스트 커버리지 >= 80%
- [ ] Brakeman 0 critical

### 4.2 Quality Criteria

- [ ] PDCA Match Rate >= 90%
- [ ] ParishScoped 격리 테스트 통과
- [ ] Auditable 동작 확인
- [ ] N+1 쿼리 없음

---

## 5. Risks and Mitigation

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| 역할 삭제 시 기존 배정 무결성 깨짐 | High | Medium | soft delete (active: false) 사용, dependent: restrict_with_error 유지 |
| EventRoleRequirement 중복 생성 | Medium | Low | uniqueness validation (role_id + event_type_id) 이미 적용 |
| 미사유형 삭제 시 관련 이벤트 영향 | High | Medium | soft delete + dependent: restrict_with_error |
| 템플릿 UI 복잡도 | Medium | Medium | Turbo Frame으로 inline 편집, 단순 폼 |

---

## 6. Architecture Considerations

### 6.1 Already Implemented (F01)

- **Role** 모델: name, description, requires_baptism, requires_confirmation, min_age, max_members, sort_order, active (ParishScoped, Auditable)
- **EventType** 모델: name, description, default_time, active (ParishScoped)
- **EventRoleRequirement** 모델: event_type_id, role_id, required_count (Auditable)
- **Qualification** 모델: name, description, validity_months (ParishScoped)
- **MemberQualification** 모델: member_id, qualification_id, acquired_date, expires_date (Auditable)

### 6.2 Controller Structure

```
Admin::RolesController < ApplicationController
  ├── index (역할 목록, sort_order 정렬)
  ├── show (상세 + 해당 역할이 필요한 미사유형 목록)
  ├── new/create (등록 - admin)
  ├── edit/update (수정 - admin)
  └── toggle_active (비활성화/활성화 - admin)

Admin::EventTypesController < ApplicationController
  ├── index (미사유형 목록)
  ├── show (상세 + 역할 템플릿)
  ├── new/create (등록 - admin)
  ├── edit/update (수정 - admin)
  └── toggle_active (비활성화/활성화 - admin)

Admin::EventRoleRequirementsController < ApplicationController
  ├── create (미사유형에 역할 추가)
  ├── update (필요인원수 수정)
  └── destroy (미사유형에서 역할 제거)
```

### 6.3 Key Files to Create/Modify

| File | Action | Description |
|------|--------|-------------|
| `app/controllers/admin/roles_controller.rb` | Create | 역할 CRUD + toggle_active |
| `app/controllers/admin/event_types_controller.rb` | Create | 미사유형 CRUD + toggle_active |
| `app/controllers/admin/event_role_requirements_controller.rb` | Create | 템플릿 CRUD (nested) |
| `app/policies/role_policy.rb` | Create | admin: 전체, operator: index/show |
| `app/policies/event_type_policy.rb` | Create | admin: 전체, operator: index/show |
| `app/views/admin/roles/index.html.erb` | Create | 역할 목록 |
| `app/views/admin/roles/show.html.erb` | Create | 역할 상세 |
| `app/views/admin/roles/_form.html.erb` | Create | 역할 등록/수정 폼 |
| `app/views/admin/roles/new.html.erb` | Create | 역할 등록 |
| `app/views/admin/roles/edit.html.erb` | Create | 역할 수정 |
| `app/views/admin/event_types/index.html.erb` | Create | 미사유형 목록 |
| `app/views/admin/event_types/show.html.erb` | Create | 미사유형 상세 + 역할 템플릿 |
| `app/views/admin/event_types/_form.html.erb` | Create | 미사유형 등록/수정 폼 |
| `app/views/admin/event_types/new.html.erb` | Create | 미사유형 등록 |
| `app/views/admin/event_types/edit.html.erb` | Create | 미사유형 수정 |
| `app/views/admin/event_types/_requirement_form.html.erb` | Create | 역할 추가 폼 (Turbo Frame) |
| `app/models/event_type.rb` | Modify | Auditable concern 추가 |
| `config/routes.rb` | Modify | admin namespace에 roles, event_types 라우트 |
| `app/views/layouts/_navbar.html.erb` | Modify | 역할/미사유형 관리 메뉴 추가 |
| `app/views/dashboard/index.html.erb` | Modify | 역할/미사유형 카드 추가 |
| `spec/factories/roles.rb` | Create | Role factory |
| `spec/factories/event_types.rb` | Create | EventType factory |
| `spec/factories/event_role_requirements.rb` | Create | EventRoleRequirement factory |
| `spec/requests/admin/roles_spec.rb` | Create | 역할 request spec |
| `spec/requests/admin/event_types_spec.rb` | Create | 미사유형 request spec |
| `spec/policies/role_policy_spec.rb` | Create | RBAC spec |
| `spec/policies/event_type_policy_spec.rb` | Create | RBAC spec |

---

## 7. Implementation Estimate

| Phase | Items | Estimated Effort |
|-------|:---:|---|
| RolesController + views | 6 files | Medium |
| EventTypesController + views | 7 files | Medium |
| EventRoleRequirementsController | 2 files | Small |
| Policies | 2 files | Small |
| Routes + Navbar + Dashboard | 3 files | Small |
| Factories + Specs | 7 files | Medium |
| **Total** | **~27 files** | **Medium-Large** |

---

## 8. Next Steps

1. [ ] Write design document (`F04-roles.design.md`)
2. [ ] Review and approval
3. [ ] Implementation (Do phase)
4. [ ] Gap analysis (Check phase)

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | 2026-02-16 | Initial plan document | CTO Lead |
