# F07: Response Flow Design Document

> **Feature**: 수락/거절 응답 + 대타 요청 플로우
> **Phase**: Design
> **Date**: 2026-02-16

---

## 1. Architecture Overview

```
[봉사자] --토큰링크--> ResponsesController (인증불필요)
   └──> show: 배정 정보 표시
   └──> update: 수락/거절 처리
         ├── 수락: status → accepted
         └── 거절: status → declined
              └── [운영자] → 대타 추천 → substitute 배정
                   └── 원래 배정: status → replaced
```

## 2. Model Changes

### 2.1 Assignment Model 확장

```ruby
# app/models/assignment.rb 에 추가
TOKEN_EXPIRY_HOURS = 72

def generate_response_token!
  update!(
    response_token: SecureRandom.urlsafe_base64(32),
    response_token_expires_at: TOKEN_EXPIRY_HOURS.hours.from_now
  )
end

def accept!
  update!(status: "accepted", responded_at: Time.current)
end

def decline!(reason = nil)
  update!(status: "declined", responded_at: Time.current, decline_reason: reason)
end

def respondable?
  pending? && token_valid?
end

scope :declined_without_substitute, -> {
  where(status: "declined").where(replaced_by_id: nil)
}

scope :needing_substitute, -> {
  declined_without_substitute
}
```

## 3. Controller Design

### 3.1 ResponsesController (New)

토큰 기반 접근 - 인증 불필요

```ruby
# app/controllers/responses_controller.rb
class ResponsesController < ApplicationController
  skip_before_action :require_authentication
  layout "response"  # 간소화 레이아웃

  before_action :find_assignment_by_token

  def show
    # 토큰으로 배정 정보 표시
  end

  def update
    if params[:response] == "accept"
      @assignment.accept!
      redirect_to completed_response_path(@assignment.response_token)
    elsif params[:response] == "decline"
      @assignment.decline!(params[:decline_reason])
      redirect_to completed_response_path(@assignment.response_token)
    end
  end

  def completed
    @assignment = Assignment.find_by!(response_token: params[:token])
  end

  private

  def find_assignment_by_token
    @assignment = Assignment.find_by!(response_token: params[:token])
    unless @assignment.respondable?
      render :expired, status: :gone
    end
  end
end
```

### 3.2 AssignmentsController 확장

```ruby
# substitute 액션 추가
def substitute
  @original = @event.assignments.find(params[:id])
  authorize @original, :create?

  @substitute = @event.assignments.build(
    role_id: @original.role_id,
    member_id: params[:member_id],
    assigned_by: Current.user,
    status: "pending"
  )

  if @substitute.save
    @original.update!(status: "replaced", replaced_by_id: @substitute.member_id)
    @substitute.generate_response_token!
    redirect_to event_path(@event), notice: "대타가 배정되었습니다."
  else
    redirect_to event_path(@event), alert: @substitute.errors.full_messages.join(", ")
  end
end
```

## 4. Routes

```ruby
# config/routes.rb
resources :responses, only: [], param: :token do
  member do
    get :show, path: ""
    patch :update, path: ""
    get :completed
  end
end
# 또는 간단하게:
get "respond/:token", to: "responses#show", as: :response
patch "respond/:token", to: "responses#update"
get "respond/:token/completed", to: "responses#completed", as: :completed_response

# 대타 배정
resources :events do
  resources :assignments do
    member do
      post :substitute
    end
  end
end
```

## 5. View Design

### 5.1 Response Layout (app/views/layouts/response.html.erb)

모바일 최적화 간소화 레이아웃 (navbar 없음, 풀스크린)

### 5.2 Response Show (app/views/responses/show.html.erb)

```
┌─────────────────────────────┐
│   AltarServe Manager        │
│                             │
│   봉사 배정 알림             │
│                             │
│   📅 2026-02-23 (일)        │
│   ⏰ 09:00                  │
│   ⛪ 주일미사                │
│   🎭 십자가봉사              │
│                             │
│  ┌─────────┐ ┌────────────┐ │
│  │  수락 ✓  │ │  거절 ✗    │ │
│  └─────────┘ └────────────┘ │
│                             │
│  거절 사유 (선택):           │
│  ┌─────────────────────────┐│
│  │                         ││
│  └─────────────────────────┘│
└─────────────────────────────┘
```

### 5.3 Expired Page (app/views/responses/expired.html.erb)

만료/이미응답 시 안내 메시지

### 5.4 Completed Page (app/views/responses/completed.html.erb)

응답 완료 감사 메시지 + 결과 표시

### 5.5 Events Show 확장

거절된 배정에 "대타 배정" 버튼 추가
Turbo Frame으로 대타 후보 인라인 추천

## 6. Implementation Order

| Phase | Files | Description |
|-------|-------|-------------|
| A | app/models/assignment.rb | generate_response_token!, accept!, decline!, respondable?, scopes |
| B | app/views/layouts/response.html.erb | 모바일 최적화 응답 레이아웃 |
| C | app/controllers/responses_controller.rb | 토큰 기반 응답 처리 |
| D | app/views/responses/*.html.erb | show, expired, completed 뷰 |
| E | config/routes.rb | 응답 + 대타 라우트 |
| F | app/controllers/assignments_controller.rb | substitute 액션 |
| G | app/views/events/show.html.erb | 대타 추천 UI |
| H | spec/**/*_spec.rb | 테스트 |

## 7. Test Plan

### 7.1 Model Tests (spec/models/assignment_response_spec.rb)
- generate_response_token! 토큰 생성 (4)
- accept! 상태 변경 (1)
- decline! 상태 변경 + 사유 (1)
- respondable? 조건 (3)
- declined_without_substitute scope (2)

### 7.2 Request Tests (spec/requests/responses_spec.rb)
- GET /respond/:token 배정 정보 표시 (1)
- PATCH /respond/:token accept (1)
- PATCH /respond/:token decline (1)
- 만료 토큰 접근 시 410 (1)
- 이미 응답한 토큰 접근 시 410 (1)
- 잘못된 토큰 접근 시 404 (1)
- GET completed 표시 (1)

### 7.3 Request Tests (spec/requests/assignments_substitute_spec.rb)
- POST substitute 대타 배정 (1)
- 원래 배정 replaced 상태 변경 (1)
- 대타 토큰 생성 확인 (1)
- member 권한 거부 (1)

총 테스트: 22개
