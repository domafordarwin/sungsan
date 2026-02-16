# F05: Event/Schedule Management Plan

> **Summary**: 미사/행사 일정 CRUD 및 반복 일정 자동 생성
>
> **Feature**: F05-events
> **Version**: 1.0
> **Date**: 2026-02-16
> **Status**: Draft
> **Dependencies**: F01-bootstrap, F02-auth, F04-roles (EventType templates)

---

## 1. Overview

### 1.1 Purpose

미사/행사 일정을 등록, 조회, 수정, 삭제하는 관리 기능을 구현합니다.
단건 등록과 반복 일정 자동 생성(주일미사 4주분, 평일미사 등)을 지원하며,
EventType 템플릿과 연동하여 배정 인원 기준을 자동 로드합니다.

### 1.2 Related Requirements

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-04 | 미사/행사 일정 등록 (단건/반복) | High |
| FR-05 | 반복 일정 자동 생성 (주일 1~4차, 평일 등) | High |

---

## 2. Functional Requirements

### 2.1 Event CRUD (FR-04)

| ID | Requirement | Role |
|----|-------------|------|
| F05-01 | 이벤트 생성 (날짜, 시간, 미사유형, 제목, 장소, 비고) | admin, operator |
| F05-02 | 이벤트 목록 조회 (날짜별/미사유형별 필터) | admin, operator |
| F05-03 | 이벤트 상세 조회 (배정현황 요약 표시) | admin, operator |
| F05-04 | 이벤트 수정 | admin, operator |
| F05-05 | 이벤트 삭제 (배정이 없는 경우만) | admin |
| F05-06 | EventType 선택 시 default_time 자동 입력 | admin, operator |
| F05-07 | EventType의 역할 템플릿(EventRoleRequirement) 요약 표시 | admin, operator |

### 2.2 Recurring Events (FR-05)

| ID | Requirement | Role |
|----|-------------|------|
| F05-08 | 반복 일정 생성 (요일 + 주 수 지정) | admin |
| F05-09 | 반복 그룹 식별 (recurring_group_id) | system |
| F05-10 | 반복 일정 일괄 삭제 (그룹 단위) | admin |

### 2.3 List & Filter

| ID | Requirement | Role |
|----|-------------|------|
| F05-11 | 다가오는 일정 목록 (기본 뷰) | admin, operator |
| F05-12 | 지난 일정 목록 | admin, operator |
| F05-13 | 날짜 범위 필터 | admin, operator |
| F05-14 | 미사유형 필터 | admin, operator |

---

## 3. Non-Functional Requirements

| Category | Criteria |
|----------|----------|
| Authorization | admin: 전체 CRUD, operator: 생성/조회/수정 (삭제 불가) |
| ParishScoped | 본당 단위 데이터 격리 |
| Auditable | 이벤트 생성/수정/삭제 감사로그 |
| Performance | 목록 조회 < 200ms (1000건 기준) |

---

## 4. Existing Assets

### 4.1 Event Model (이미 구현됨)

```ruby
class Event < ApplicationRecord
  include ParishScoped
  include Auditable
  belongs_to :event_type
  has_many :assignments, dependent: :destroy
  has_many :attendance_records, dependent: :destroy
  validates :date, presence: true
  validates :start_time, presence: true
  scope :upcoming, :past, :on_date, :this_week, :this_month
  def display_name; end
end
```

### 4.2 Migration (이미 생성됨)

- `events` 테이블: parish_id, event_type_id, title, date, start_time, end_time, location, notes, recurring_group_id
- 인덱스: `[parish_id, date]`, `recurring_group_id`

### 4.3 신규 구현 필요

- EventsController (CRUD + bulk_create)
- EventPolicy
- Views (index, show, _form, new, edit)
- Routes
- Request/Policy specs

---

## 5. Scope Boundaries

### In Scope (F05)
- Event CRUD (단건)
- 반복 일정 생성 (날짜 자동 계산)
- 필터/검색
- EventType 연동 (default_time, 역할 템플릿 요약)

### Out of Scope (다른 Feature)
- 배정 관리 (F06-assignment)
- 수락/거절 응답 (F07-response)
- 출결 기록 (F08-attendance)
- 알림 발송 (F09-notifications)

---

## 6. Estimated File Count

| Category | Files |
|----------|:-----:|
| Controller | 1 |
| Policy | 1 |
| Views | 5 |
| Routes (수정) | 1 |
| Navigation (수정) | 1 |
| Dashboard (수정) | 1 |
| Request Spec | 1 |
| Policy Spec | 1 |
| **Total** | ~12 |

---

## 7. Implementation Order

```
Phase A: Policy (EventPolicy)
Phase B: Controller (EventsController - CRUD + bulk_create)
Phase C: Views (index, show, _form, new, edit)
Phase D: Routes & Navigation
Phase E: Tests (request spec + policy spec)
```

---

## 8. Risks

| Risk | Mitigation |
|------|-----------|
| 반복 일정 대량 생성 시 성능 | 최대 12주(3개월) 제한, 트랜잭션 처리 |
| 배정 있는 이벤트 삭제 | dependent: :restrict_with_error 또는 삭제 전 검증 |
| 날짜 필터 범위 과다 | 기본 범위를 이번 달로 제한, 페이지네이션 적용 |

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | 2026-02-16 | Initial F05 plan | Claude |
