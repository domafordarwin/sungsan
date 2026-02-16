# AltarServe Manager - Development Conventions

> **Project**: AltarServe Manager (성단 매니저)
> **Date**: 2026-02-16
> **Status**: Approved

---

## 1. Tech Stack Confirmed

| Category | Technology | Version |
|----------|-----------|---------|
| Language | Ruby | 3.2+ |
| Framework | Rails | 8.0 |
| Database | PostgreSQL | 16+ |
| Queue | Solid Queue | Rails 8 기본 (DB-backed) |
| Cache | Solid Cache | Rails 8 기본 (DB-backed) |
| WebSocket | Solid Cable | Rails 8 기본 (DB-backed) |
| Authentication | Rails 8 빌트인 generator | - |
| Authorization | Pundit | 2.x |
| Frontend | Hotwire 2.0 (Turbo + Stimulus) | Rails 8 기본 |
| Assets | Propshaft + Import Maps | Rails 8 기본 |
| Testing | RSpec | 7.x |
| Linting | RuboCop + rubocop-rails-omakase | |
| Security Scan | Brakeman + bundler-audit | |
| Deployment | Railway (Postgres addon) | Redis 불필요 |

---

## 2. Project Structure (Rails Monolith)

```
sungsan/
├── app/
│   ├── controllers/
│   │   ├── application_controller.rb
│   │   ├── admin/                     # Admin namespace
│   │   │   ├── parishes_controller.rb
│   │   │   ├── members_controller.rb
│   │   │   ├── roles_controller.rb
│   │   │   └── audit_logs_controller.rb
│   │   ├── events_controller.rb
│   │   ├── assignments_controller.rb
│   │   ├── attendance_records_controller.rb
│   │   ├── responses_controller.rb    # Token-based responses
│   │   ├── substitute_requests_controller.rb
│   │   ├── notifications_controller.rb
│   │   └── statistics_controller.rb
│   │
│   ├── models/
│   │   ├── concerns/
│   │   │   ├── auditable.rb           # 감사로그 자동 기록
│   │   │   ├── parish_scoped.rb       # 멀티 본당 스코프
│   │   │   └── maskable.rb            # 개인정보 마스킹
│   │   ├── parish.rb
│   │   ├── user.rb
│   │   ├── member.rb
│   │   ├── role.rb
│   │   ├── event_type.rb
│   │   ├── event.rb
│   │   ├── event_role_requirement.rb
│   │   ├── assignment.rb
│   │   ├── attendance_record.rb
│   │   ├── availability_rule.rb
│   │   ├── blackout_period.rb
│   │   ├── qualification.rb
│   │   ├── member_qualification.rb
│   │   ├── notification.rb
│   │   └── audit_log.rb
│   │
│   ├── services/                       # Service Objects (핵심 비즈니스 로직)
│   │   ├── assignment_engine.rb        # 자동 배정 알고리즘
│   │   ├── schedule_generator.rb       # 반복 일정 생성
│   │   ├── substitute_finder.rb        # 대타 후보 추천
│   │   ├── attendance_recorder.rb      # 출결 일괄 입력
│   │   ├── notification_sender.rb      # 알림 발송
│   │   └── statistics_calculator.rb    # 통계 집계
│   │
│   ├── policies/                       # Pundit 정책
│   │   ├── application_policy.rb
│   │   ├── member_policy.rb
│   │   ├── event_policy.rb
│   │   ├── assignment_policy.rb
│   │   └── ...
│   │
│   ├── jobs/                           # Sidekiq 잡
│   │   ├── schedule_generator_job.rb
│   │   ├── reminder_job.rb
│   │   ├── substitute_finder_job.rb
│   │   └── statistics_aggregator_job.rb
│   │
│   ├── views/
│   │   ├── layouts/
│   │   ├── shared/                     # 공통 파셜
│   │   ├── admin/
│   │   ├── events/
│   │   ├── assignments/
│   │   ├── responses/                  # 모바일 최적화
│   │   └── statistics/
│   │
│   ├── javascript/                     # Hotwire (Turbo + Stimulus)
│   │   ├── controllers/                # Stimulus 컨트롤러
│   │   │   ├── calendar_controller.js
│   │   │   ├── assignment_controller.js
│   │   │   └── notification_controller.js
│   │   └── application.js
│   │
│   └── mailers/
│       ├── assignment_mailer.rb
│       ├── reminder_mailer.rb
│       └── notification_mailer.rb
│
├── config/
│   ├── routes.rb
│   ├── initializers/
│   │   ├── devise.rb
│   │   ├── sidekiq.rb
│   │   └── pundit.rb
│   └── locales/
│       └── ko.yml                      # 한국어 번역
│
├── db/
│   ├── migrate/
│   ├── seeds.rb                        # 기본 역할/미사유형 시드
│   └── seeds/
│       ├── roles.rb
│       └── event_types.rb
│
├── spec/                               # RSpec 테스트
│   ├── models/
│   ├── services/
│   ├── controllers/
│   ├── policies/
│   ├── jobs/
│   ├── features/                       # Capybara E2E
│   ├── factories/
│   ├── support/
│   │   ├── devise.rb
│   │   ├── pundit.rb
│   │   └── database_cleaner.rb
│   └── benchmarks/                     # 성능 테스트
│
├── docs/                               # PDCA 문서 (git 제외)
│
├── Gemfile
├── Procfile                            # Railway 배포
├── .rubocop.yml
├── .github/
│   └── workflows/
│       └── ci.yml
└── CLAUDE.md
```

---

## 3. Naming Conventions

### 3.1 Ruby/Rails

| Category | Convention | Example |
|----------|-----------|---------|
| Model | singular, PascalCase | `Member`, `EventType` |
| Table | plural, snake_case | `members`, `event_types` |
| Controller | plural, PascalCase | `MembersController` |
| Service | descriptive, PascalCase | `AssignmentEngine` |
| Job | descriptive + Job | `ReminderJob` |
| Policy | model + Policy | `MemberPolicy` |
| Concern | adjective/able | `Auditable`, `ParishScoped` |
| Migration | descriptive | `CreateMembers`, `AddStatusToAssignments` |

### 3.2 Database

| Category | Convention | Example |
|----------|-----------|---------|
| Primary Key | `id` (bigint) | `members.id` |
| Foreign Key | `{table_singular}_id` | `parish_id`, `member_id` |
| Timestamps | `created_at`, `updated_at` | Rails default |
| Boolean | `is_` prefix 생략 (Rails 관례) | `active`, `confirmed` |
| Enum/Status | string type | `status: "pending"` |
| Index | `index_{table}_{columns}` | `index_assignments_on_event_id` |

### 3.3 Variables & Methods

```ruby
# Good
member.active?
assignment.accepted?
event.upcoming_this_week

# Bad
member.isActive
assignment.getStatus
event.get_upcoming_events_for_this_week
```

---

## 4. Code Patterns

### 4.1 Service Object Pattern

```ruby
# app/services/assignment_engine.rb
class AssignmentEngine
  def initialize(event:, role_requirements:)
    @event = event
    @role_requirements = role_requirements
  end

  def recommend
    @role_requirements.map do |requirement|
      candidates = filter_candidates(requirement)
      scored = score_candidates(candidates, requirement)
      {
        role: requirement.role,
        candidates: scored.first(TOP_K)
      }
    end
  end

  private

  def filter_candidates(requirement)
    # ...
  end

  def score_candidates(candidates, requirement)
    # ...
  end
end
```

### 4.2 Concern Pattern

```ruby
# app/models/concerns/parish_scoped.rb
module ParishScoped
  extend ActiveSupport::Concern

  included do
    belongs_to :parish
    default_scope { where(parish_id: Current.parish_id) if Current.parish_id }
  end
end
```

### 4.3 Policy Pattern (Pundit)

```ruby
# app/policies/assignment_policy.rb
class AssignmentPolicy < ApplicationPolicy
  def create?
    user.admin? || user.operator?
  end

  def update?
    user.admin? || user.operator?
  end

  def show?
    user.admin? || user.operator? || record.member == user.member
  end
end
```

---

## 5. Error Handling

```ruby
# app/controllers/application_controller.rb
class ApplicationController < ActionController::Base
  include Pundit

  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  rescue_from ActiveRecord::RecordNotFound, with: :not_found

  private

  def user_not_authorized
    flash[:alert] = '접근 권한이 없습니다.'
    redirect_to(request.referrer || root_path)
  end

  def not_found
    render file: "#{Rails.root}/public/404.html", status: :not_found
  end
end
```

---

## 6. Environment Variables

| Variable | Purpose | Required |
|----------|---------|:--------:|
| `DATABASE_URL` | PostgreSQL 연결 | O |
| `SECRET_KEY_BASE` | Rails 시크릿 키 | O |
| `RAILS_ENV` | 환경 (production/staging) | O |
| `REDIS_URL` | Redis 연결 (Sidekiq/Cache) | O |
| `SMTP_ADDRESS` | 이메일 서버 | O |
| `SMTP_PORT` | 이메일 포트 | O |
| `SMTP_USERNAME` | 이메일 사용자 | O |
| `SMTP_PASSWORD` | 이메일 비밀번호 | O |
| `SENTRY_DSN` | Sentry 에러 트래킹 | - |
| `RAILS_LOG_LEVEL` | 로그 레벨 | - |

---

## 7. Git Workflow

### Branch Strategy

```
main (production)
  └── develop
       ├── feature/F01-bootstrap
       ├── feature/F02-auth
       ├── feature/F03-members
       └── ...
```

### Commit Message Format

```
[F{number}] {type}: {description}

Types: feat, fix, refactor, test, docs, chore

Examples:
[F01] feat: create initial database schema with 15 tables
[F02] feat: implement Devise authentication with RBAC
[F06] fix: correct scoring weight calculation in AssignmentEngine
[F06] test: add regression tests for assignment algorithm
```

### PR Rules

- Feature branch에서 develop으로 PR
- CI 통과 필수
- 최소 1 리뷰 (code-analyzer Agent)

---

## 8. Rails 8.0 Specific Notes

| Topic | Note |
|-------|------|
| Authentication | `bin/rails generate authentication` 빌트인 사용 |
| Assets | Propshaft (Sprockets 대체) + Import Maps (Webpacker 대체) |
| Background Jobs | Solid Queue (DB-backed, Redis 불필요) |
| Caching | Solid Cache (DB-backed, Redis 불필요) |
| WebSocket | Solid Cable (DB-backed, Redis 불필요) |
| Web Server | Puma + Thruster (Nginx 불필요) |
| Frontend | Hotwire 2.0 (Turbo Frames/Streams + Stimulus) |
| Credentials | `bin/rails credentials:edit` |
| Strong Parameters | 모든 컨트롤러에서 필수 |
| CSRF | `protect_from_forgery with: :exception` |

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | 2026-02-16 | Initial conventions document | CTO Lead |
