# F08: Attendance Management Plan

> **Feature**: 출결 관리 (일괄 입력 + 봉사자별 이력)
> **Priority**: High
> **Dependencies**: F05-events
> **Date**: 2026-02-16

---

## 1. Requirements Mapping

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-12 | 출결 기록 (일괄 입력) | High |
| FR-13 | 봉사자별 출결/봉사 이력 조회 | High |

## 2. Scope

- 이벤트별 출결 일괄 입력 (배정된 봉사자 기준)
- 출결 상태: present, late, absent, excused, replaced
- 봉사자별 출결 이력 조회 (멤버 상세)
- 출결 수정
- RBAC: operator/admin만 기록 가능

## 3. Files

| Action | File | Purpose |
|--------|------|---------|
| Create | app/controllers/attendance_records_controller.rb | 출결 CRUD |
| Create | app/policies/attendance_record_policy.rb | 권한 |
| Create | app/views/attendance_records/edit.html.erb | 일괄 입력 폼 |
| Modify | app/views/events/show.html.erb | 출결 링크 |
| Modify | app/views/members/show.html.erb | 봉사이력 표시 |
| Create | spec/requests/attendance_records_spec.rb | 테스트 |
| Create | spec/policies/attendance_record_policy_spec.rb | 테스트 |
