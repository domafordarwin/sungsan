# F06: Assignment Management Plan

> **Summary**: 수동 배정 관리 + 자동 배정 추천
>
> **Feature**: F06-assignment
> **Version**: 1.0
> **Date**: 2026-02-16
> **Dependencies**: F05-events, F04-roles, F03-members

---

## 1. Overview

이벤트(미사)에 봉사자를 역할별로 배정하는 기능입니다.
EventType의 역할 템플릿(EventRoleRequirement) 기반으로 필요 인원을 파악하고,
수동 배정(운영자 직접 선택)과 자동 추천(후보 스코어링)을 지원합니다.

## 2. Related Requirements

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-06 | 자동 배정 추천 (필터링 + 스코어링) | Critical |
| FR-07 | 수동 배정 (운영자 직접 편집) | High |

## 3. Functional Requirements

| ID | Requirement | Role |
|----|-------------|------|
| F06-01 | 이벤트 상세에서 역할별 배정 관리 (추가/제거) | admin, operator |
| F06-02 | 배정 가능 봉사자 목록 (역할 자격 필터) | admin, operator |
| F06-03 | 배정 생성 (member + role + event) | admin, operator |
| F06-04 | 배정 취소 (status → canceled) | admin, operator |
| F06-05 | 배정자 기록 (assigned_by = Current.user) | system |
| F06-06 | 자동 추천 후보 목록 (스코어링) | admin, operator |
| F06-07 | 추천 기준: 활성 + 자격조건 + 가용성 + 최근 배정 횟수 | system |
| F06-08 | 배정 현황 요약 (역할별 필요/배정/부족) | admin, operator |

## 4. Existing Assets

- Assignment 모델 완비 (statuses, scopes, token 관련)
- AvailabilityRule, BlackoutPeriod 모델 완비
- Event.assignment_summary 메서드 (F05에서 구현)
- EventRoleRequirement 템플릿 (F04에서 구현)
- Member 모델 (active, baptized, confirmed scopes)

## 5. Scope

### In Scope
- 수동 배정 CRUD (이벤트 show 페이지 내 인라인)
- 자동 추천 후보 리스트 (점수 기반)
- 배정 현황 요약

### Out of Scope
- 수락/거절 응답 (F07-response)
- 대타 요청 플로우 (F07-response)
- 알림 발송 (F09-notifications)

## 6. Estimated Files: ~10

| Category | Files |
|----------|:-----:|
| Policy | 1 |
| Controller | 1 |
| Views (partials) | 2 |
| Event show 수정 | 1 |
| Service Object | 1 |
| Routes 수정 | 1 |
| Request Spec | 1 |
| Policy Spec | 1 |
| Service Spec | 1 |
