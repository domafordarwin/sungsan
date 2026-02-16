# AltarServe Manager MVP Planning Document

> **Summary**: 가톨릭 성당 전례 봉사자(복사) 관리 자동화 웹앱 MVP 개발 계획
>
> **Project**: AltarServe Manager (성단 매니저)
> **Version**: 0.1.0
> **Author**: CTO Lead
> **Date**: 2026-02-16
> **Status**: Approved

---

## 1. Overview

### 1.1 Purpose

미사/전례 일정에 맞춰 성단 봉사자를 자동 배정하고, 출결/자격/연락/통계를
한 곳에서 관리하는 웹 애플리케이션을 개발합니다.

### 1.2 Background

현장(본당 전례팀/성단 담당)에서 반복되는 운영 문제:
- 봉사자 정보 분산 (엑셀/단톡/수기)으로 최신성/정합성 저하
- 역할 배정이 수작업으로 누락/중복/불공정 발생
- 대체자(대타) 수급/변경 히스토리 관리 어려움
- 출결 기록 비체계화
- 알림/리마인더가 단체방 중심으로 추적 불가

### 1.3 Related Documents

- PRD: `docs/PRD_altarserve_manager.md`
- TRD: `docs/TRD_altarserve_manager.md`
- Team Composition: `docs/01-plan/00-team-composition.md`
- Development Pipeline: `docs/01-plan/01-development-pipeline.md`
- QA Strategy: `docs/01-plan/02-qa-strategy.md`
- Conventions: `docs/01-plan/03-conventions.md`

---

## 2. Scope

### 2.1 In Scope (P0 MVP)

- [x] 봉사자(신자) 등록/수정/비활성화, 연락처, 소속, 기본 선호
- [x] 역할 템플릿 정의 (미사 유형별 필요한 역할/인원수)
- [x] 미사/행사 일정 등록 (반복 생성 포함)
- [x] 자동 배정 (로테이션 + 자격조건 + 이력 기반 후보 추천)
- [x] 수동 배정 (캘린더/표 기반 편집)
- [x] 배정 알림 + 수락/거절 (모바일 웹)
- [x] 거절 시 대타 요청 플로우
- [x] 출결 기록 (담당자 입력 + 봉사자 확인)
- [x] 공지 발송 (이벤트/역할/전체 단위)
- [x] 기본 통계 (역할별 인력 부족, 참여율, 결석률, 월별 봉사 횟수)
- [x] RBAC (admin, operator, member)
- [x] 감사로그
- [x] 개인정보 마스킹

### 2.2 Out of Scope

- 교적/헌금/본당 전체 행정 시스템 (P2)
- 전례문 편집/출력 기능
- 실시간 채팅/메신저 자체 구현
- 카카오/문자 연동 (P1)
- 교육 이수 관리 (P1)
- 멀티테넌시 (P2, 단 DB 설계에서 parish_id 스코프 미리 적용)
- QR/지오펜스 출결 (P2)

---

## 3. Requirements

### 3.1 Functional Requirements

| ID | Requirement | Priority | Feature |
|----|-------------|----------|---------|
| FR-01 | 봉사자 CRUD (등록/조회/수정/비활성화) | High | F03 |
| FR-02 | 봉사자 연락처, 소속(구역/단체), 선호 관리 | High | F03 |
| FR-03 | 역할 정의 및 미사유형별 템플릿 | High | F04 |
| FR-04 | 미사/행사 일정 등록 (단건/반복) | High | F05 |
| FR-05 | 반복 일정 자동 생성 (주일 1~4차, 평일 등) | High | F05 |
| FR-06 | 자동 배정 추천 (필터링 + 스코어링) | Critical | F06 |
| FR-07 | 수동 배정 (운영자 직접 편집) | High | F06 |
| FR-08 | 배정 알림 발송 | High | F09 |
| FR-09 | 봉사자 수락/거절 (토큰 기반 링크) | High | F07 |
| FR-10 | 거절 시 대타 요청 플로우 | High | F07 |
| FR-11 | 대타 후보 자동 추천 | Medium | F07 |
| FR-12 | 출결 기록 (일괄 입력) | High | F08 |
| FR-13 | 봉사자별 출결/봉사 이력 조회 | High | F08 |
| FR-14 | 공지 발송 (이벤트/역할/전체) | Medium | F09 |
| FR-15 | 통계 (참여율, 결석률, 월별 봉사 횟수) | Medium | F10 |
| FR-16 | 역할별 인력 부족 경고 | Medium | F10 |
| FR-17 | RBAC (admin/operator/member) | Critical | F02 |
| FR-18 | 감사로그 (배정/출결/자격 변경 기록) | High | F02 |
| FR-19 | 개인정보 마스킹 (역할별 부분 마스킹) | High | F03 |
| FR-20 | 모바일 웹 최적화 (수락/거절 동선) | High | F07 |

### 3.2 Non-Functional Requirements

| Category | Criteria | Measurement Method |
|----------|----------|-------------------|
| Performance | 배정 추천 < 2초 (2000명 기준) | Benchmark test |
| Performance | 페이지 로드 < 500ms | Rails logs |
| Security | RBAC 100% 적용 | Pundit policy tests |
| Security | 개인정보 마스킹 적용 | Security test suite |
| Security | 감사로그 100% 기록 | Audit log tests |
| Reliability | 테스트 커버리지 >= 80% | SimpleCov |
| Usability | 수락/거절 2클릭 이내 | Feature test |
| Scalability | 200~2000명 규모 지원 | Load test |

---

## 4. Success Criteria

### 4.1 Definition of Done

- [ ] P0 기능 요구사항 20개 전체 구현
- [ ] RSpec 테스트 통과 (커버리지 >= 80%)
- [ ] RBAC 테스트 전체 통과
- [ ] 배정 알고리즘 회귀 테스트 통과
- [ ] Brakeman 보안 스캔 Critical 0
- [ ] RuboCop lint 통과
- [ ] Railway 배포 완료
- [ ] 3대 사용자 플로우 E2E 테스트 통과

### 4.2 Quality Criteria

- [ ] Match Rate >= 90% (모든 Feature)
- [ ] Critical Issues = 0
- [ ] 성능 기준 충족 (2000명 배정 < 2초)
- [ ] 보안 기준 충족 (OWASP Top 10 대응)

---

## 5. Risks and Mitigation

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| 배정 알고리즘 복잡도 초과 | High | Medium | MVP는 규칙 기반으로 단순화, 가중치 설정 가능하게 설계 |
| Rails 8 gem 호환성 | Low | Low | 주요 gem (Pundit, RSpec) 모두 Rails 8 호환 확인 |
| 개인정보 보호 이슈 | High | Medium | 최소 수집 + 마스킹 + 감사로그 + 접근제어 |
| 모바일 UX 부족 | Medium | Medium | 수락/거절 링크 최소 동선 설계, 반응형 CSS |
| 성능 저하 (대규모 본당) | Medium | Low | 인덱스 최적화, N+1 방지, 벤치마크 테스트 |
| Sidekiq 잡 실패 | Medium | Low | 리트라이 정책 + 에러 알림 (Sentry) |

---

## 6. Architecture Considerations

### 6.1 Project Level Selection

| Level | Characteristics | Recommended For | Selected |
|-------|-----------------|-----------------|:--------:|
| **Starter** | Simple structure | Static sites, portfolios | |
| **Dynamic** | Feature-based modules, BaaS | Web apps with backend | |
| **Enterprise** | Strict layer separation, DI | Complex architectures | O |

**Rationale**: 15개 이상 테이블, 복잡한 배정 알고리즘, RBAC, 감사로그 등
Enterprise 수준의 품질 관리가 필요하나, 기술 스택은 Rails 모놀리식으로 유지합니다.

### 6.2 Key Architectural Decisions

| Decision | Options | Selected | Rationale |
|----------|---------|----------|-----------|
| Framework | Rails 8.0 | Rails 8.0 | 최신 안정 버전, Ruby 3.2+ |
| Auth | Rails 8 빌트인 + Pundit | Rails 8 빌트인 + Pundit | 빌트인 인증 + RBAC |
| Background Jobs | Solid Queue | Solid Queue | DB-backed, Redis 불필요 |
| Frontend | Hotwire 2.0 (Turbo + Stimulus) | Hotwire 2.0 | Rails 8 기본 |
| Assets | Propshaft + Import Maps | Propshaft | Webpacker 대체 |
| Testing | RSpec | RSpec | Rails 표준, FactoryBot 지원 |
| Deployment | Railway | Railway | Postgres addon, Redis 불필요 |
| DB | PostgreSQL | PostgreSQL 16+ | 안정적, Solid Queue 호환 |

### 6.3 Clean Architecture Approach

```
Selected Level: Enterprise (Rails Monolith variant)

Rails Architecture:
┌─────────────────────────────────────────────────────┐
│ Presentation Layer                                   │
│   Controllers + Views + Stimulus                     │
├─────────────────────────────────────────────────────┤
│ Application Layer                                    │
│   Service Objects (AssignmentEngine, etc.)           │
│   Policies (Pundit)                                  │
│   Jobs (Sidekiq)                                     │
├─────────────────────────────────────────────────────┤
│ Domain Layer                                         │
│   Models (ActiveRecord) + Concerns                   │
│   Business Rules (validations, state machines)       │
├─────────────────────────────────────────────────────┤
│ Infrastructure Layer                                 │
│   Database (PostgreSQL)                              │
│   Cache (Redis)                                      │
│   External Services (Email)                          │
└─────────────────────────────────────────────────────┘
```

---

## 7. Convention Prerequisites

### 7.1 Existing Project Conventions

- [x] `CLAUDE.md` has project overview
- [ ] `docs/01-plan/03-conventions.md` created (this plan)
- [ ] RuboCop configuration (`.rubocop.yml`)
- [ ] RSpec configuration (`spec/spec_helper.rb`, `spec/rails_helper.rb`)
- [ ] CI configuration (`.github/workflows/ci.yml`)

### 7.2 Conventions to Define/Verify

| Category | Current State | To Define | Priority |
|----------|---------------|-----------|:--------:|
| **Naming** | defined | Ruby/Rails 표준 + 한국어 주석 규칙 | High |
| **Folder structure** | defined | Service Objects, Policies, Jobs | High |
| **Database** | defined | 명명, 인덱스, FK 규칙 | High |
| **Error handling** | defined | 공통 에러 처리 패턴 | Medium |
| **Testing** | defined | RSpec 구조, FactoryBot 규칙 | High |

### 7.3 Environment Variables Needed

| Variable | Purpose | Scope | To Be Created |
|----------|---------|-------|:-------------:|
| `DATABASE_URL` | PostgreSQL 연결 | Server | O |
| `SECRET_KEY_BASE` | Rails 시크릿 | Server | O |
| `RAILS_ENV` | 환경 | Server | O |
| `REDIS_URL` | Redis 연결 | Server | O |
| `SMTP_ADDRESS` | 이메일 서버 | Server | O |
| `SMTP_PORT` | 이메일 포트 | Server | O |
| `SMTP_USERNAME` | 이메일 인증 | Server | O |
| `SMTP_PASSWORD` | 이메일 비밀번호 | Server | O |

---

## 8. Feature PDCA Execution Order

아래 순서로 각 Feature를 개별 PDCA 사이클로 진행합니다.

### 8.1 Critical Path (순차 실행)

```
F01 (Bootstrap) -> F02 (Auth) -> F05 (Events) -> F06 (Assignment)
```

### 8.2 Full Execution Plan

| Order | Feature | Dependencies | PDCA Command |
|:-----:|---------|-------------|--------------|
| 1 | F01: Project Bootstrap & DB Schema | None | `/pdca plan F01-bootstrap` |
| 2 | F02: Authentication & Authorization | F01 | `/pdca plan F02-auth` |
| 3-A | F03: Parish & Member Management | F02 | `/pdca plan F03-members` |
| 3-B | F04: Role & Event Type Templates | F02 | `/pdca plan F04-roles` |
| 4 | F05: Event/Schedule Management | F04 | `/pdca plan F05-events` |
| 5 | F06: Assignment (Manual + Auto) | F05 | `/pdca plan F06-assignment` |
| 6 | F07: Response Flow | F06 | `/pdca plan F07-response` |
| 7 | F08: Attendance Management | F05 | `/pdca plan F08-attendance` |
| 8-A | F09: Notifications | F06, F07 | `/pdca plan F09-notifications` |
| 8-B | F10: Statistics & Dashboard | F06, F08 | `/pdca plan F10-statistics` |
| 9 | F11: Background Jobs | F05, F06, F09 | `/pdca plan F11-jobs` |
| 10 | F12: Integration & Polish | ALL | `/pdca plan F12-integration` |

### 8.3 Per-Feature PDCA Cycle

```
각 Feature에 대해:

1. /pdca plan {feature}     -- Plan 문서 작성
2. /pdca design {feature}   -- Design 문서 작성
3. /pdca do {feature}       -- 구현 가이드 + 코딩
4. /pdca analyze {feature}  -- Gap Analysis (Match Rate 산출)
5. /pdca iterate {feature}  -- Match Rate < 90% 시 반복
6. /pdca report {feature}   -- 완료 보고서
7. /pdca archive {feature}  -- 아카이브 (선택)
```

---

## 9. Next Steps

1. [x] Team composition document 작성 완료
2. [x] Development pipeline document 작성 완료
3. [x] QA strategy document 작성 완료
4. [x] Conventions document 작성 완료
5. [x] MVP plan document 작성 완료 (본 문서)
6. [ ] CLAUDE.md 업데이트 (Tech Stack 확정 반영)
7. [ ] F01 Plan 시작: `/pdca plan F01-bootstrap`

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | 2026-02-16 | Initial MVP plan document | CTO Lead |
