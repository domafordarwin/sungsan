# F09: Notifications Design

> **Phase**: Design
> **Date**: 2026-02-16

---

## 1. Architecture

```
Admin/Operator → NotificationsController
  ├── index: 알림 이력
  ├── new/create: 공지 작성
  └── show: 알림 상세
AssignmentsController#create → NotificationService.assignment_created
```

## 2. Controller

```ruby
class NotificationsController < ApplicationController
  def index
    authorize Notification
    @notifications = policy_scope(Notification).order(created_at: :desc).page(params[:page]).per(20)
  end

  def show
    @notification = Notification.find(params[:id])
    authorize @notification
  end

  def new
    @notification = Notification.new
    authorize @notification
  end

  def create
    @notification = Notification.new(notification_params)
    @notification.parish_id = Current.parish_id
    @notification.sender = Current.user
    @notification.notification_type = "announcement"
    @notification.status = "sent"
    @notification.sent_at = Time.current
    authorize @notification

    if @notification.save
      redirect_to notifications_path, notice: "공지가 발송되었습니다."
    else
      render :new, status: :unprocessable_entity
    end
  end
end
```

## 3. NotificationService

```ruby
class NotificationService
  def self.assignment_created(assignment)
    Notification.create!(
      parish_id: assignment.event.parish_id,
      recipient: assignment.member,
      sender_id: assignment.assigned_by_id,
      notification_type: "assignment",
      channel: "email",
      subject: "봉사 배정 알림",
      body: "#{assignment.event.display_name} - #{assignment.role.name}에 배정되었습니다.",
      status: "pending",
      related: assignment
    )
  end
end
```

## 4. Policy

```ruby
class NotificationPolicy < ApplicationPolicy
  def index?; operator_or_admin?; end
  def show?; operator_or_admin?; end
  def create?; operator_or_admin?; end
  class Scope < ApplicationPolicy::Scope
    def resolve; scope.all; end
  end
end
```

## 5. Routes

```ruby
resources :notifications, only: [:index, :show, :new, :create]
```

## 6. Views
- index: 알림 목록 (타입, 수신자, 날짜, 상태)
- show: 알림 상세
- new: 공지 작성 폼 (subject, body, channel)

## 7. Test Plan (12 tests)
- Policy: index/show/create 권한 (6)
- Request: CRUD + member denied (6)
