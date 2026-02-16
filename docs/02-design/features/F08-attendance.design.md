# F08: Attendance Management Design

> **Feature**: 출결 관리
> **Phase**: Design
> **Date**: 2026-02-16

---

## 1. Architecture

```
EventsController#show → "출결 기록" 링크
    ↓
AttendanceRecordsController#edit → 일괄 입력 폼 (배정된 봉사자 목록)
    ↓
AttendanceRecordsController#update → 일괄 저장 (upsert)
    ↓
MembersController#show → 봉사 이력 표시
```

## 2. Controller Design

### AttendanceRecordsController

```ruby
class AttendanceRecordsController < ApplicationController
  before_action :set_event

  def edit
    authorize AttendanceRecord
    @assignments = @event.assignments.accepted.includes(:member, :role)
    @records = @event.attendance_records.index_by(&:member_id)
  end

  def update
    authorize AttendanceRecord
    params[:attendance].each do |member_id, attrs|
      record = @event.attendance_records.find_or_initialize_by(member_id: member_id)
      record.assign_attributes(
        status: attrs[:status],
        reason: attrs[:reason],
        assignment_id: attrs[:assignment_id],
        recorded_by: Current.user
      )
      record.save!
    end
    redirect_to event_path(@event), notice: "출결이 기록되었습니다."
  end
end
```

## 3. Policy

```ruby
class AttendanceRecordPolicy < ApplicationPolicy
  def edit?; operator_or_admin?; end
  def update?; operator_or_admin?; end
end
```

## 4. Routes

```ruby
resources :events do
  resource :attendance, controller: "attendance_records", only: [:edit, :update]
end
```

## 5. Views

### edit.html.erb - 일괄 입력 폼
테이블 형태로 배정 봉사자 목록 + 상태 select + 사유 input

### events/show.html.erb 수정
출결 기록 버튼 추가 (지난 이벤트용)

### members/show.html.erb 수정
최근 봉사/출결 이력 테이블

## 6. Implementation Order

| Phase | Files |
|-------|-------|
| A | app/policies/attendance_record_policy.rb |
| B | app/controllers/attendance_records_controller.rb |
| C | config/routes.rb |
| D | app/views/attendance_records/edit.html.erb |
| E | app/views/events/show.html.erb (출결 링크) |
| F | app/views/members/show.html.erb (이력) |
| G | spec tests |

## 7. Test Plan (16 tests)

### Policy (4)
- edit?: admin O, operator O, member X
- update?: admin O

### Request (8)
- GET edit 폼 표시
- PATCH update 일괄 저장
- 기존 기록 업데이트
- member 권한 거부
- recorded_by 확인

### Members show (4)
- 봉사 이력 표시 확인
