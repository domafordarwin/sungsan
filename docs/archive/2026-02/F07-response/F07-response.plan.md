# F07: Response Flow (수락/거절/대타) Plan

> **Feature**: 봉사자 수락/거절 응답 + 거절 시 대타 요청 플로우
> **Priority**: High
> **Dependencies**: F06-assignment
> **Date**: 2026-02-16

---

## 1. Overview

배정된 봉사자가 토큰 기반 링크로 수락/거절을 응답하고,
거절 시 자동으로 대타 후보를 추천하여 대체 배정하는 플로우를 구현합니다.

## 2. Requirements Mapping

| ID | Requirement | Priority |
|----|-------------|----------|
| FR-09 | 봉사자 수락/거절 (토큰 기반 링크) | High |
| FR-10 | 거절 시 대타 요청 플로우 | High |
| FR-11 | 대타 후보 자동 추천 | Medium |
| FR-20 | 모바일 웹 최적화 (수락/거절 동선) | High |

## 3. Scope

### 3.1 In Scope
- 토큰 생성 및 배정 시 자동 발급
- 토큰 기반 응답 페이지 (인증 불필요)
- 수락/거절 처리 (2클릭 이내)
- 거절 시 사유 입력 (선택)
- 대타 후보 추천 (AssignmentRecommender 재활용)
- 대타 배정 (운영자/관리자)
- 원래 배정 상태 replaced 처리
- 모바일 최적화 UI

### 3.2 Out of Scope
- 이메일/SMS 발송 (F09에서 구현)
- 카카오톡 연동

## 4. Technical Approach

### 4.1 토큰 생성
- Assignment 생성 시 SecureRandom.urlsafe_base64 토큰 자동 생성
- 만료: 72시간 (설정 가능)
- 모델에 generate_response_token! 메서드

### 4.2 응답 페이지
- /respond/:token (GET) - 배정 정보 표시 + 수락/거절 버튼
- /respond/:token (PATCH) - 수락/거절 처리
- 인증 불필요 (토큰 자체가 인증)
- 만료/이미 응답 시 에러 페이지

### 4.3 대타 플로우
- 거절 시 자동으로 대타 후보 표시 (관리자/운영자 화면)
- AssignmentRecommender로 후보 추천
- 대타 배정 시 원래 배정 replaced_by 업데이트

## 5. Files to Create/Modify

| Action | File | Purpose |
|--------|------|---------|
| Modify | app/models/assignment.rb | generate_response_token!, accept!, decline! |
| Create | app/controllers/responses_controller.rb | 토큰 기반 응답 처리 |
| Create | app/views/responses/show.html.erb | 응답 페이지 (모바일 최적화) |
| Create | app/views/responses/expired.html.erb | 만료/에러 페이지 |
| Create | app/views/responses/completed.html.erb | 응답 완료 페이지 |
| Modify | app/controllers/assignments_controller.rb | 대타 배정 (substitute 액션) |
| Modify | app/views/events/show.html.erb | 거절 시 대타 추천 UI |
| Modify | config/routes.rb | 응답 라우트 추가 |
| Create | spec/requests/responses_spec.rb | 응답 API 테스트 |
| Create | spec/models/assignment_response_spec.rb | 모델 메서드 테스트 |

## 6. Success Criteria

- [ ] 토큰 기반 수락/거절 동작
- [ ] 모바일 2클릭 이내 응답 완료
- [ ] 만료 토큰 접근 시 에러 페이지
- [ ] 거절 시 대타 후보 추천
- [ ] 대타 배정 시 원래 배정 replaced 처리
- [ ] Match Rate >= 90%
