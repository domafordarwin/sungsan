# F11: Background Jobs Design

## Jobs

### AssignmentReminderJob
- 48시간 이상 미응답 배정 → 리마인더 알림
- `Assignment.pending.where("created_at < ?", 48.hours.ago)`

### EventReminderJob
- 이벤트 D-1 → accepted 봉사자에게 리마인더

## Test Plan (4 tests)
- Job 실행 시 알림 생성 확인
