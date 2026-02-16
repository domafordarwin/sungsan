# F03: Parish & Member Management Planning Document

> **Summary**: 봉사자(Member) CRUD + 개인정보 마스킹 + 검색/필터링 UI 구현
>
> **Project**: AltarServe Manager (성단 매니저)
> **Version**: 0.1.0
> **Author**: CTO Lead
> **Date**: 2026-02-16
> **Status**: Draft
> **Depends On**: F01-bootstrap (archived, 96%), F02-auth (archived, 98%)

---

## 1. Overview

### 1.1 Purpose

봉사자(Member) 정보의 등록, 조회, 수정, 비활성화를 위한 관리 UI를 구현합니다. F01에서 생성한 Member 모델과 F02의 인증/인가 시스템을 기반으로, 운영자/관리자가 봉사자 목록을 관리하고 봉사자 본인이 자신의 정보를 확인할 수 있도록 합니다.

### 1.2 Background

- F01에서 Member 모델, ParishScoped, Auditable, Maskable concern 이미 구현됨
- F02에서 Authentication, Pundit RBAC, MemberPolicy 이미 구현됨
- MVP 요구사항 FR-01, FR-02, FR-19 해당
- 봉사자 정보: 이름, 세례명, 연락처, 구역, 세례/견진 여부, 활동 상태
- 개인정보 마스킹: phone, email, birth_date (admin만 원본 열람)

### 1.3 Related Documents

- MVP Plan: `docs/01-plan/features/altarserve-mvp.plan.md` (FR-01, FR-02, FR-19)
- F01 Bootstrap: `docs/archive/2026-02/F01-bootstrap/`
- F02 Auth: `docs/archive/2026-02/F02-auth/`
- Conventions: `docs/01-plan/03-conventions.md`

---

## 2. Scope

### 2.1 In Scope

- [x] 봉사자 목록 (검색, 필터링, 페이지네이션)
- [x] 봉사자 상세 조회 (마스킹 적용)
- [x] 봉사자 등록 (admin만)
- [x] 봉사자 수정 (admin/operator)
- [x] 봉사자 비활성화/활성화 (admin만, 삭제 대신 soft delete)
- [x] 봉사자-사용자 연결 (User와 Member 1:1 연동)
- [x] 개인정보 마스킹 적용 (Maskable concern 활용)
- [x] 검색: 이름, 세례명, 구역으로 검색
- [x] 필터: 활동 상태, 세례/견진 여부, 구역
- [x] 봉사자 본인 프로필 조회
- [x] 감사로그 자동 기록 (Auditable concern)

### 2.2 Out of Scope

- 봉사자 일괄 등록 (CSV import) - P1
- 봉사자 사진 관리 - P2
- 자격증/교육 이수 관리 - F04에서 Qualification 연동
- 봉사 이력/출결 통계 - F08, F10
- 봉사자 선호 일정 관리 - F05 (AvailabilityRule, BlackoutPeriod)

---

## 3. Requirements

### 3.1 Functional Requirements

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-01 | 봉사자 목록 (페이지네이션 포함) | Critical | Pending |
| FR-02 | 봉사자 상세 조회 | Critical | Pending |
| FR-03 | 봉사자 등록 (admin) | High | Pending |
| FR-04 | 봉사자 수정 (admin/operator) | High | Pending |
| FR-05 | 봉사자 비활성화/활성화 (admin) | High | Pending |
| FR-06 | 이름/세례명/구역 검색 | High | Pending |
| FR-07 | 필터링 (활동상태, 세례, 견진, 구역) | Medium | Pending |
| FR-08 | 개인정보 마스킹 (phone, email, birth_date) | Critical | Pending |
| FR-09 | 봉사자-User 연결/해제 | Medium | Pending |
| FR-10 | 본인 프로필 조회 (member 역할) | High | Pending |
| FR-11 | 감사로그 자동 기록 | High | Pending (Auditable 활용) |

### 3.2 Non-Functional Requirements

| Category | Criteria | Measurement Method |
|----------|----------|-------------------|
| Performance | 목록 조회 < 200ms (1000명 기준) | Rails logs |
| Security | 개인정보 마스킹 100% 적용 | Policy spec |
| Security | RBAC 정책 100% 적용 | Policy spec |
| Usability | 봉사자 등록 3분 이내 | Manual test |
| Usability | 모바일 반응형 | Visual test |

---

## 4. Success Criteria

### 4.1 Definition of Done

- [ ] MembersController CRUD 완료
- [ ] 검색/필터링 작동
- [ ] 개인정보 마스킹 뷰에서 적용
- [ ] MemberPolicy RBAC 테스트 통과
- [ ] Request spec + Policy spec 작성
- [ ] RSpec 테스트 커버리지 >= 80%
- [ ] Brakeman 0 critical

### 4.2 Quality Criteria

- [ ] PDCA Match Rate >= 90%
- [ ] 마스킹 테스트 전체 통과
- [ ] N+1 쿼리 없음

---

## 5. Risks and Mitigation

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| 마스킹 누락으로 개인정보 노출 | High | Medium | masked_* 헬퍼만 뷰에서 사용, spec으로 검증 |
| N+1 쿼리 성능 저하 | Medium | Medium | includes/preload 활용, bullet gem (P1) |
| ParishScoped 기본 스코프 간섭 | Low | Medium | 관리자 조회 시 unscoped_by_parish 활용 |

---

## 6. Architecture Considerations

### 6.1 Already Implemented (F01/F02)

- Member 모델 (ParishScoped, Auditable, Maskable)
- MemberPolicy (admin: 전체, operator: 조회/수정, member: 본인만)
- User-Member 1:1 관계
- Authentication concern + Current attributes

### 6.2 Controller Structure

```
MembersController < ApplicationController
  ├── index (목록 + 검색 + 필터)
  ├── show (상세 - 마스킹 적용)
  ├── new/create (등록 - admin)
  ├── edit/update (수정 - admin/operator)
  └── toggle_active (비활성화/활성화 - admin)

ProfileController < ApplicationController
  └── show (본인 프로필 - member)
```

### 6.3 Key Files to Create/Modify

| File | Action | Description |
|------|--------|-------------|
| `app/controllers/members_controller.rb` | Create | 봉사자 CRUD + 검색/필터 |
| `app/controllers/profile_controller.rb` | Create | 본인 프로필 |
| `app/views/members/index.html.erb` | Create | 목록 (검색/필터 포함) |
| `app/views/members/show.html.erb` | Create | 상세 (마스킹 적용) |
| `app/views/members/_form.html.erb` | Create | 등록/수정 폼 |
| `app/views/members/new.html.erb` | Create | 등록 |
| `app/views/members/edit.html.erb` | Create | 수정 |
| `app/views/profile/show.html.erb` | Create | 본인 프로필 |
| `config/routes.rb` | Modify | members + profile 라우트 |
| `app/views/layouts/_navbar.html.erb` | Modify | 봉사자 관리 메뉴 추가 |
| `spec/requests/members_spec.rb` | Create | Request spec |
| `spec/requests/profile_spec.rb` | Create | Profile spec |
| `spec/policies/member_policy_spec.rb` | Modify | 추가 테스트 |

---

## 7. Implementation Estimate

| Phase | Items | Estimated Effort |
|-------|:---:|---|
| MembersController + views | 6 files | Medium |
| ProfileController + view | 2 files | Small |
| Routes + Navbar update | 2 files | Small |
| Search/Filter logic | 1 file | Small |
| Specs (request + policy) | 3 files | Medium |
| **Total** | **~14 files** | **Medium** |

---

## 8. Next Steps

1. [ ] Write design document (`F03-members.design.md`)
2. [ ] Review and approval
3. [ ] Implementation (Do phase)
4. [ ] Gap analysis (Check phase)

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | 2026-02-16 | Initial plan document | CTO Lead |
