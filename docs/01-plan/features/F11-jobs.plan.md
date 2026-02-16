# F11: Background Jobs Plan

> **Feature**: 백그라운드 잡 (Solid Queue)
> **Dependencies**: F05, F06, F09

## Scope
- AssignmentReminderJob: 미응답 배정 리마인더
- EventReminderJob: 일정 D-1 리마인더
- Solid Queue 설정 (DB 기반, Redis 불필요)
- MVP에서는 Job 클래스 정의 + 스케줄 설정까지 (실제 cron은 배포 후)
