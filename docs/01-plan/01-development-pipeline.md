# AltarServe Manager - Development Pipeline

> **Project**: AltarServe Manager (성단 매니저)
> **Date**: 2026-02-16
> **Status**: Approved

---

## 1. Pipeline Overview

전체 개발은 Feature 단위 PDCA 사이클로 진행합니다.
각 Feature는 독립적인 Plan -> Design -> Do -> Check -> Act -> Report 사이클을 가집니다.

```
Phase 0: Project Setup (공통 기반)
    │
    v
Phase 1: Foundation Features (P0 기반)
    ├── F01: Project Bootstrap & DB Schema
    ├── F02: Authentication & Authorization
    ├── F03: Parish & Member Management
    ├── F04: Role & Event Type Templates
    │
    v
Phase 2: Core Features (P0 핵심)
    ├── F05: Event/Schedule Management
    ├── F06: Assignment (Manual + Auto)
    ├── F07: Response Flow (Accept/Decline/Substitute)
    ├── F08: Attendance Management
    │
    v
Phase 3: Communication & Analytics (P0 완성)
    ├── F09: Notifications & Announcements
    ├── F10: Statistics & Dashboard
    │
    v
Phase 4: Integration & Polish (P0 MVP 마감)
    ├── F11: Background Jobs (Sidekiq)
    ├── F12: End-to-End Integration & Polish
    │
    v
[MVP Release]
```

---

## 2. Feature Breakdown & PDCA Schedule

### Phase 0: Project Setup

**목적**: 모든 Feature의 공통 기반 구성

| Task | Description | Duration |
|------|-------------|----------|
| Rails 프로젝트 생성 | `rails new` with PostgreSQL | 0.5일 |
| Gemfile 구성 | Devise, Sidekiq, RSpec, SimpleCov 등 | 0.5일 |
| DB 스키마 초안 마이그레이션 | 15개 핵심 테이블 | 1일 |
| CI 기본 설정 | GitHub Actions (lint + test) | 0.5일 |
| Seed 데이터 | 개발용 기본 데이터 | 0.5일 |

**산출물**: 빈 Rails 프로젝트 + 전체 DB 스키마 + CI

---

### Phase 1: Foundation Features

#### F01: Project Bootstrap & DB Schema
```
PDCA Priority: Critical Path
Estimated Effort: 2 days

Plan  : DB 스키마 설계 확정 (ERD, 관계, 인덱스)
Design: 마이그레이션 순서, 시드 데이터 설계
Do    : rails new, 마이그레이션, 모델 기본 관계 설정
Check : 스키마 검증, 모델 테스트 (유효성, 관계)
Act   : 피드백 반영
```

**Key Tables**: parishes, users, members, roles, event_types, events,
event_role_requirements, assignments, attendance_records, availability_rules,
blackout_periods, qualifications, member_qualifications, notifications, audit_logs

#### F02: Authentication & Authorization
```
PDCA Priority: Critical Path
Estimated Effort: 2 days

Plan  : Devise 설정, RBAC 정책 정의
Design: 인증 플로우, 권한 매트릭스, 세션 관리
Do    : Devise 설치/설정, RBAC 구현 (Pundit/CanCanCan)
Check : 역할별 접근 테스트, 보안 검증
Act   : 보안 이슈 수정
```

**RBAC Matrix**:

| Resource | admin | operator | member |
|----------|:-----:|:--------:|:------:|
| parishes | CRUD | R | R |
| members | CRUD | RU | R(self) |
| events | CRUD | CRUD | R |
| assignments | CRUD | CRUD | R(self) |
| attendance | CRUD | CRU | R(self) |
| statistics | R | R | R(limited) |
| audit_logs | R | - | - |

#### F03: Parish & Member Management
```
PDCA Priority: High
Estimated Effort: 2 days

Plan  : 봉사자 CRUD 요구사항, 검색/필터 정의
Design: 화면 설계, 폼 필드, 마스킹 규칙
Do    : 컨트롤러, 뷰, 서비스 객체 구현
Check : CRUD 테스트, 개인정보 마스킹 검증
Act   : UI/UX 개선
```

#### F04: Role & Event Type Templates
```
PDCA Priority: High
Estimated Effort: 1.5 days

Plan  : 역할 정의, 미사 유형별 템플릿 구조
Design: 템플릿 데이터 모델, 관리 화면
Do    : 역할/미사유형 CRUD, 역할별 필요인원 설정
Check : 템플릿 기능 테스트
Act   : 피드백 반영
```

---

### Phase 2: Core Features

#### F05: Event/Schedule Management
```
PDCA Priority: Critical Path
Estimated Effort: 3 days

Plan  : 일정 생성 규칙, 반복 패턴 정의
Design: 반복 일정 생성 알고리즘, 캘린더 뷰
Do    : 일정 CRUD, 반복 생성 로직, 캘린더 UI
Check : 반복 생성 정확도, 엣지 케이스 테스트
Act   : 날짜 계산 버그 수정
```

#### F06: Assignment (Manual + Auto)
```
PDCA Priority: Critical Path (핵심 기능)
Estimated Effort: 4 days

Plan  : 자동 배정 알고리즘 상세 요구사항
Design: 필터링/스코어링 알고리즘, 수동 배정 UI
Do    : AssignmentEngine 서비스, 수동 배정 UI
Check : 알고리즘 정확도, 공정성 검증, 회귀 테스트
Act   : 알고리즘 튜닝, 엣지 케이스 처리
```

**Algorithm Detail**:
```
Input: event, role_requirements, candidate_members

Step 1: Filter
  - active? AND role_capable? AND qualified?
  - NOT in blackout_period?
  - NOT already_assigned_same_time?

Step 2: Score (lower = higher priority)
  - recent_role_count(N weeks) * w1
  - recent_total_count * w2
  - decline_penalty * w3
  - preference_bonus * w4

Step 3: Output
  - Top K candidates per role
  - Operator confirms or auto-assigns
```

#### F07: Response Flow (Accept/Decline/Substitute)
```
PDCA Priority: High
Estimated Effort: 3 days

Plan  : 수락/거절/대타 플로우 정의
Design: 토큰 기반 응답, 대타 후보 추천, 상태 전이
Do    : 응답 컨트롤러, 대타 요청/수락, 상태 머신
Check : 상태 전이 무결성, 토큰 보안 테스트
Act   : 엣지 케이스 처리
```

**State Machine**:
```
pending -> accepted (봉사자 수락)
pending -> declined (봉사자 거절)
declined -> substitute_requested (대타 요청)
substitute_requested -> replaced (대타 수락)
any -> canceled (운영자 취소)
```

#### F08: Attendance Management
```
PDCA Priority: High
Estimated Effort: 2 days

Plan  : 출결 입력 방식, 통계 연동 정의
Design: 일괄 출결 UI, 이력 조회 화면
Do    : 출결 CRUD, 일괄 입력, 봉사자 이력 뷰
Check : 출결 데이터 정합성 테스트
Act   : 피드백 반영
```

---

### Phase 3: Communication & Analytics

#### F09: Notifications & Announcements
```
PDCA Priority: Medium-High
Estimated Effort: 2.5 days

Plan  : 알림 종류, 채널, 타이밍 정의
Design: 알림 시스템 아키텍처, 템플릿
Do    : Notification 서비스, 이메일 발송, 공지 기능
Check : 알림 발송/수신 테스트
Act   : 피드백 반영
```

#### F10: Statistics & Dashboard
```
PDCA Priority: Medium
Estimated Effort: 2.5 days

Plan  : 통계 항목 정의, 시각화 요구사항
Design: 집계 쿼리, 대시보드 레이아웃
Do    : 통계 서비스, 차트 (Chartkick/Chart.js), 대시보드
Check : 데이터 정확도, 성능 테스트
Act   : 쿼리 최적화
```

---

### Phase 4: Integration & Polish

#### F11: Background Jobs (Sidekiq)
```
PDCA Priority: Medium
Estimated Effort: 2 days

Plan  : 백그라운드 잡 목록, 스케줄 정의
Design: 잡 설계, 리트라이 정책, 모니터링
Do    : Sidekiq 잡 구현, 스케줄러 설정
Check : 잡 실행 안정성, 에러 처리 테스트
Act   : 실패 처리 강화
```

**Jobs**:
- ScheduleGeneratorJob: 반복 일정 자동 생성
- ReminderJob: 미사 전 리마인더 (48h/24h/3h)
- SubstituteFinderJob: 거절 시 대타 후보 자동 추천
- StatisticsAggregatorJob: 월별 통계 집계

#### F12: End-to-End Integration & Polish
```
PDCA Priority: High
Estimated Effort: 3 days

Plan  : 통합 테스트 시나리오, 성능 기준
Design: E2E 테스트 설계, 배포 체크리스트
Do    : 통합 테스트, UI 정리, 배포 설정
Check : 전체 플로우 E2E 테스트, 성능 벤치마크
Act   : 최종 수정
```

---

## 3. Feature Dependencies

```
F01 (Bootstrap/Schema)
  └─> F02 (Auth/RBAC)
       └─> F03 (Members)
       └─> F04 (Roles/Templates)
            └─> F05 (Events/Schedule)
                 └─> F06 (Assignment) ─────> F07 (Response Flow)
                 └─> F08 (Attendance)
       └─> F09 (Notifications) [F06, F07에 의존]
       └─> F10 (Statistics) [F06, F08에 의존]
  └─> F11 (Background Jobs) [F05, F06, F09에 의존]
       └─> F12 (Integration) [ALL에 의존]
```

---

## 4. Parallel Execution Opportunities

Swarm 패턴을 활용할 수 있는 병렬 구현 구간:

| Parallel Group | Features | Condition |
|----------------|----------|-----------|
| Group A | F03 + F04 | F02 완료 후 동시 진행 가능 |
| Group B | F07 + F08 | F06 진행 중 F08 선행 가능 |
| Group C | F09 + F10 | F06, F08 완료 후 동시 진행 가능 |

---

## 5. Total Estimated Timeline

| Phase | Duration | Cumulative |
|-------|----------|------------|
| Phase 0: Setup | 3 days | Day 3 |
| Phase 1: Foundation | 7.5 days | Day 10.5 |
| Phase 2: Core | 12 days | Day 22.5 |
| Phase 3: Communication | 5 days | Day 27.5 |
| Phase 4: Integration | 5 days | Day 32.5 |
| **Total** | **~33 working days** | |

**Note**: 각 Feature의 PDCA 사이클(특히 Check-Act 반복)에 따라 조정될 수 있습니다.

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | 2026-02-16 | Initial pipeline design | CTO Lead |
