# F02: User Authentication & Authorization Planning Document

> **Summary**: Rails 8 빌트인 인증 + Pundit RBAC 기반 사용자 인증/인가 시스템 구현
>
> **Project**: AltarServe Manager (성단 매니저)
> **Version**: 0.1.0
> **Author**: CTO Lead
> **Date**: 2026-02-16
> **Status**: Draft
> **Depends On**: F01-bootstrap (completed, 96% match)

---

## 1. Overview

### 1.1 Purpose

AltarServe Manager의 사용자 인증(Authentication)과 역할 기반 접근 제어(RBAC Authorization)를 구현합니다. Rails 8의 빌트인 인증 generator를 활용하여 세션 기반 로그인/로그아웃을 구현하고, Pundit으로 admin/operator/member 3단계 권한을 제어합니다.

### 1.2 Background

- F01에서 User/Session 모델, `has_secure_password`, 3단계 role 필드가 이미 구현됨
- Rails 8은 `bin/rails generate authentication`으로 세션 컨트롤러/뷰를 자동 생성
- 모든 API/페이지에 인증이 필수 (로그인 페이지 제외)
- RBAC: admin(전체 관리), operator(미사 담당 운영), member(본인 정보만)
- MVP 범위: 이메일+비밀번호 로그인 (소셜 로그인은 P2)

### 1.3 Related Documents

- MVP Plan: `docs/01-plan/features/altarserve-mvp.plan.md` (FR-17, FR-18)
- F01 Bootstrap: `docs/archive/2026-02/F01-bootstrap/` (archived)
- PRD: `docs/PRD_altarserve_manager.md`
- Conventions: `docs/01-plan/03-conventions.md`

---

## 2. Scope

### 2.1 In Scope

- [x] Rails 8 빌트인 인증 generator 적용 (SessionsController, Authentication concern)
- [x] 로그인/로그아웃 UI (Turbo 기반)
- [x] 세션 관리 (IP/User-Agent 기록, 다중 세션)
- [x] Current.user / Current.parish_id 설정 (ApplicationController)
- [x] Pundit 정책 (ApplicationPolicy + 모델별 Policy)
- [x] RBAC 3단계: admin > operator > member
- [x] 비밀번호 변경 기능
- [x] 관리자용 사용자 관리 (CRUD)
- [x] 감사로그 연동 (로그인/로그아웃/비밀번호 변경 기록)
- [x] 인증 실패 처리 (3회 실패 시 잠금 등은 P1, 기본 오류 메시지만)
- [x] 레이아웃 기본 구조 (네비게이션, 로그인 상태 표시)

### 2.2 Out of Scope

- 소셜 로그인 (Google, KakaoTalk) - P2
- 이메일 인증 (가입 시 이메일 확인) - P1
- 비밀번호 재설정 (이메일 발송) - P1
- 2FA (이중 인증) - P2
- API 토큰 인증 (REST API용) - P2
- 회원가입 (관리자가 사용자 생성) - In Scope

---

## 3. Requirements

### 3.1 Functional Requirements

| ID | Requirement | Priority | Status |
|----|-------------|----------|--------|
| FR-01 | 이메일 + 비밀번호 로그인 | Critical | Pending |
| FR-02 | 로그아웃 (세션 삭제) | Critical | Pending |
| FR-03 | 세션 관리 (IP/UA 기록, 만료) | High | Pending |
| FR-04 | Current.user 설정 (ApplicationController) | Critical | Pending |
| FR-05 | Current.parish_id 자동 설정 | Critical | Pending |
| FR-06 | Pundit ApplicationPolicy 기본 정책 | Critical | Pending |
| FR-07 | 관리자: 사용자 생성 (이메일+이름+역할+비밀번호) | High | Pending |
| FR-08 | 관리자: 사용자 목록/상세 조회 | High | Pending |
| FR-09 | 관리자: 사용자 역할 변경 | High | Pending |
| FR-10 | 관리자: 사용자 비활성화/삭제 | High | Pending |
| FR-11 | 본인 비밀번호 변경 | Medium | Pending |
| FR-12 | 인증 실패 시 에러 메시지 | High | Pending |
| FR-13 | 미인증 접근 시 로그인 페이지 리다이렉트 | Critical | Pending |
| FR-14 | 로그인/로그아웃 감사로그 기록 | High | Pending |
| FR-15 | 기본 레이아웃 (네비게이션바, 로그인 상태) | High | Pending |

### 3.2 Non-Functional Requirements

| Category | Criteria | Measurement Method |
|----------|----------|-------------------|
| Security | 비밀번호 bcrypt 해싱 (has_secure_password) | Code review |
| Security | 세션 고정 공격 방지 (로그인 시 세션 재생성) | Security test |
| Security | CSRF 토큰 검증 | Rails 기본 |
| Security | Pundit 정책 100% 적용 (after_action :verify_authorized) | Policy spec |
| Performance | 로그인 응답 < 200ms | Rails logs |
| Usability | 로그인 폼 모바일 반응형 | Visual test |

---

## 4. Success Criteria

### 4.1 Definition of Done

- [ ] Rails 8 Authentication generator 적용
- [ ] 로그인/로그아웃 정상 작동
- [ ] Pundit 정책 모든 컨트롤러에 적용
- [ ] 관리자 사용자 관리 CRUD 완료
- [ ] 비밀번호 변경 기능 완료
- [ ] 감사로그 연동 완료
- [ ] RSpec 테스트 통과 (커버리지 >= 80%)
- [ ] Brakeman 0 critical

### 4.2 Quality Criteria

- [ ] PDCA Match Rate >= 90%
- [ ] Controller spec + Request spec + Policy spec 작성
- [ ] 인증 실패 시나리오 테스트 포함

---

## 5. Risks and Mitigation

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Rails 8 auth generator 커스터마이즈 난이도 | Medium | Low | Generator 기본 코드 활용 후 점진적 수정 |
| Pundit 정책 누락으로 권한 우회 | High | Medium | after_action :verify_authorized 필수 적용, Policy spec 100% |
| 세션 만료 미처리로 보안 취약 | Medium | Low | 세션 타임아웃 설정 (2주) |
| Current.parish_id 미설정으로 데이터 유출 | High | Medium | before_action으로 필수 설정, 테스트에서 검증 |

---

## 6. Architecture Considerations

### 6.1 Rails 8 Authentication Generator

Rails 8에서 `bin/rails generate authentication` 실행 시 자동 생성되는 항목:
- `app/controllers/sessions_controller.rb`
- `app/controllers/concerns/authentication.rb`
- `app/views/sessions/new.html.erb`
- `app/models/user.rb` (has_secure_password 추가 -- 이미 있음)
- `app/models/session.rb` (이미 있음)
- `app/models/current.rb` (이미 있음)

**F01에서 이미 구현된 항목**: User, Session, Current 모델 -> Generator 대신 수동으로 컨트롤러/뷰 작성

### 6.2 Authentication Flow

```
[로그인 페이지] -> POST /session -> [SessionsController#create]
  -> User.authenticate_by(email_address:, password:)
  -> 성공: Session 생성 + 리다이렉트
  -> 실패: 에러 메시지 + 로그인 페이지

[인증 필요 페이지] -> before_action :require_authentication
  -> Session 쿠키 확인 -> Current.user 설정
  -> 미인증: 로그인 페이지 리다이렉트
```

### 6.3 RBAC Policy Structure

```
ApplicationPolicy (기본: admin만 허용)
  ├── UserPolicy (admin: 전체, operator/member: 본인만)
  ├── MemberPolicy (admin: 전체, operator: 조회/수정, member: 본인)
  ├── RolePolicy (admin: 전체, operator: 조회)
  ├── EventPolicy (admin/operator: 전체, member: 조회)
  ├── AssignmentPolicy (admin/operator: 전체, member: 본인 응답만)
  └── ... (후속 Feature에서 추가)
```

### 6.4 Controller Structure

```
ApplicationController
  ├── include Authentication (세션 검증)
  ├── before_action :require_authentication
  ├── before_action :set_current_attributes
  └── after_action :verify_authorized (Pundit)

SessionsController < ApplicationController
  skip_before_action :require_authentication
  ├── new (로그인 폼)
  ├── create (로그인 처리)
  └── destroy (로그아웃)

PasswordsController < ApplicationController
  ├── edit (비밀번호 변경 폼)
  └── update (비밀번호 변경 처리)

Admin::UsersController < ApplicationController
  ├── index (사용자 목록)
  ├── show (사용자 상세)
  ├── new/create (사용자 생성)
  ├── edit/update (사용자 수정)
  └── destroy (사용자 삭제)
```

### 6.5 Key Files to Create/Modify

| File | Action | Description |
|------|--------|-------------|
| `app/controllers/application_controller.rb` | Create | Authentication + Current 설정 + Pundit |
| `app/controllers/concerns/authentication.rb` | Create | Rails 8 인증 concern |
| `app/controllers/sessions_controller.rb` | Create | 로그인/로그아웃 |
| `app/controllers/passwords_controller.rb` | Create | 비밀번호 변경 |
| `app/controllers/admin/users_controller.rb` | Create | 관리자 사용자 관리 |
| `app/policies/application_policy.rb` | Create | Pundit 기본 정책 |
| `app/policies/user_policy.rb` | Create | 사용자 접근 정책 |
| `app/views/sessions/new.html.erb` | Create | 로그인 페이지 |
| `app/views/passwords/edit.html.erb` | Create | 비밀번호 변경 |
| `app/views/admin/users/` | Create | 사용자 관리 뷰 |
| `app/views/layouts/application.html.erb` | Create | 기본 레이아웃 |
| `config/routes.rb` | Create | 라우팅 |
| `spec/controllers/` | Create | 컨트롤러 스펙 |
| `spec/requests/` | Create | Request 스펙 |
| `spec/policies/` | Create | Policy 스펙 |

---

## 7. Convention Prerequisites

### 7.1 Existing Conventions (from F01)

- [x] `CLAUDE.md` has tech stack and conventions
- [x] `docs/01-plan/03-conventions.md` exists
- [x] `.rubocop.yml` configured
- [x] RSpec + FactoryBot configured
- [x] ParishScoped concern for multi-tenant
- [x] Auditable concern for audit logging

### 7.2 New Conventions for F02

| Category | Convention | Priority |
|----------|-----------|:--------:|
| Controllers | snake_case, RESTful 7 actions | High |
| Views | ERB + Turbo Frames, `app/views/{resource}/` | High |
| Policies | `{Model}Policy` in `app/policies/` | High |
| Routes | RESTful resources, namespace :admin | High |
| Specs | `spec/requests/`, `spec/policies/`, `spec/system/` | High |
| Flash | `notice` (성공), `alert` (실패) | Medium |

### 7.3 Environment Variables

| Variable | Purpose | Scope | Default |
|----------|---------|-------|---------|
| `SECRET_KEY_BASE` | Rails secret | Server | Auto-generated |
| `DATABASE_URL` | DB connection | Server | From database.yml |

---

## 8. Implementation Estimate

| Phase | Items | Estimated Effort |
|-------|:---:|---|
| Authentication concern + SessionsController | 3 files | Small |
| ApplicationController + Current setup | 2 files | Small |
| Pundit policies (Application + User) | 2 files | Small |
| Admin::UsersController + views | 6 files | Medium |
| PasswordsController + views | 2 files | Small |
| Routes | 1 file | Small |
| Layout + Navigation | 2 files | Small |
| Specs (request + policy + system) | 6 files | Medium |
| **Total** | **~24 files** | **Medium** |

---

## 9. Next Steps

1. [ ] Write design document (`F02-auth.design.md`)
2. [ ] Review and approval
3. [ ] Implementation (Do phase)
4. [ ] Gap analysis (Check phase)

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | 2026-02-16 | Initial plan document | CTO Lead |
