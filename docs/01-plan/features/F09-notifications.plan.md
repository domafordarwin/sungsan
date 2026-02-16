# F09: Notifications Plan

> **Feature**: 알림 발송 (배정알림 + 공지)
> **Priority**: Medium-High
> **Dependencies**: F06, F07

---

## Requirements

| ID | Requirement |
|----|-------------|
| FR-08 | 배정 알림 발송 |
| FR-14 | 공지 발송 (이벤트/역할/전체) |

## Scope

- NotificationsController: 알림 목록/상세/발송
- 공지 작성 및 발송 (admin/operator)
- 알림 이력 조회
- 배정 시 자동 알림 생성 (서비스 연동)
- 이메일 발송은 ActionMailer 기본 구조만 (실제 SMTP는 환경설정 의존)
