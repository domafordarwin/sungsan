# F01: Project Bootstrap & DB Schema - Planning Document

> **Summary**: Rails 8 프로젝트 초기화, 15개 핵심 테이블 DB 스키마 생성, CI 기본 설정
>
> **Project**: AltarServe Manager (성단 매니저)
> **Version**: 0.1.0
> **Author**: CTO Lead
> **Date**: 2026-02-16
> **Status**: Draft
> **PDCA Phase**: Plan

---

## 1. Overview

### 1.1 Purpose

Rails 8 프로젝트를 생성하고 PRD/TRD에 정의된 15개 핵심 테이블의 DB 스키마를 구축합니다.
모든 후속 Feature(F02~F12)의 공통 기반이 되는 Foundation 작업입니다.

### 1.2 Tech Stack Confirmation (Rails 8)

| Category | Technology | Version | Note |
|----------|-----------|---------|------|
| Language | Ruby | 3.2+ | Rails 8 최소 요구 |
| Framework | Rails | 8.0 | 최신 안정 버전 |
| Database | PostgreSQL | 16+ | Railway Postgres addon |
| Queue | Solid Queue | (Rails 8 기본) | DB-backed, Redis 불필요 |
| Cache | Solid Cache | (Rails 8 기본) | DB-backed |
| WebSocket | Solid Cable | (Rails 8 기본) | DB-backed |
| Auth | Rails 8 빌트인 + Pundit | - | Devise 대신 빌트인 사용 |
| Frontend | Hotwire 2.0 (Turbo + Stimulus) | - | Rails 8 기본 |
| Assets | Propshaft + Import Maps | - | Webpacker/Sprockets 대체 |
| Testing | RSpec 5.x + FactoryBot | - | Rails 기본 Minitest 대신 |
| Lint | RuboCop + rubocop-rails | - | 코드 품질 |
| Security | Brakeman + bundler-audit | - | 보안 스캔 |
| Deploy | Railway | - | Postgres addon 사용 |

### 1.3 Rails 8 핵심 변경사항 (vs Rails 5.2)

| 변경 항목 | 영향 | 대응 |
|-----------|------|------|
| Solid Trifecta (Queue/Cache/Cable) | Redis 의존성 제거 | Railway에서 Redis 서비스 불필요 |
| 빌트인 인증 generator | Devise 불필요 | `bin/rails generate authentication` 사용 |
| Hotwire 2.0 (Turbo + Stimulus) | SPA-like UX 기본 제공 | Turbo Frames/Streams 활용 |
| Propshaft + Import Maps | Webpacker/Node.js 불필요 | JS 번들링 없이 ES modules 직접 사용 |
| Kamal 2 (기본 배포) | Docker 기반 배포 | Railway 사용하므로 Kamal 미사용 |
| Thruster (기본 웹서버 프록시) | Nginx 불필요 | Puma + Thruster로 정적 파일 서빙 |

### 1.4 Related Documents

- PRD: `docs/PRD_altarserve_manager.md`
- TRD: `docs/TRD_altarserve_manager.md`
- MVP Plan: `docs/01-plan/features/altarserve-mvp.plan.md`
- Conventions: `docs/01-plan/03-conventions.md`

---

## 2. Scope

### 2.1 In Scope

- [x] Rails 8 프로젝트 생성 (`rails new` with PostgreSQL)
- [x] Gemfile 구성 (RSpec, FactoryBot, Pundit, SimpleCov, Brakeman 등)
- [x] 15개 핵심 테이블 마이그레이션 생성 및 실행
- [x] ActiveRecord 모델 생성 (관계, 유효성, 인덱스)
- [x] 공통 Concerns 생성 (Auditable, ParishScoped, Maskable)
- [x] Seed 데이터 (기본 역할, 미사 유형 템플릿)
- [x] RSpec 기본 설정 (spec_helper, rails_helper, FactoryBot)
- [x] RuboCop 설정 (.rubocop.yml)
- [x] GitHub Actions CI 설정 (lint + test)
- [x] Procfile (Railway 배포용)

### 2.2 Out of Scope

- 인증/인가 구현 (F02에서 진행)
- 컨트롤러/뷰 구현 (F03~에서 진행)
- Solid Queue 잡 구현 (F11에서 진행)
- Railway 실제 배포 (F12에서 진행)

---

## 3. Database Schema

### 3.1 핵심 테이블 (15개)

```
parishes ─────────────────────────────────────────────────
  │ (멀티 본당 지원, 모든 테이블의 스코프)
  │
  ├── users ──────────────────────────────────────────────
  │     │ (로그인 계정, Rails 8 빌트인 인증)
  │     │ role: admin | operator | member
  │     │
  │     └── members ──────────────────────────────────────
  │           │ (봉사자 프로필: 이름, 연락처, 소속 등)
  │           │
  │           ├── availability_rules ─────────────────────
  │           │     (가능 요일/시간/미사 종류)
  │           │
  │           ├── blackout_periods ───────────────────────
  │           │     (휴가/시험 등 불가 기간)
  │           │
  │           └── member_qualifications ──────────────────
  │                 (교육/자격 이수 기록)
  │
  ├── roles ──────────────────────────────────────────────
  │     (역할 정의: 독서, 해설, 복사 등)
  │
  ├── qualifications ─────────────────────────────────────
  │     (자격/교육 정의)
  │
  ├── event_types ────────────────────────────────────────
  │     │ (미사 유형: 주일, 평일, 대축일 등)
  │     │
  │     └── event_role_requirements ──────────────────────
  │           (미사 유형별 필요 역할/인원수)
  │
  ├── events ─────────────────────────────────────────────
  │     │ (개별 미사/행사 인스턴스)
  │     │
  │     └── assignments ──────────────────────────────────
  │           │ (event × role × member 배정)
  │           │ status: pending|accepted|declined|replaced|canceled
  │           │
  │           └── attendance_records ─────────────────────
  │                 (출결 기록)
  │                 status: present|late|absent|excused|replaced
  │
  ├── notifications ──────────────────────────────────────
  │     (알림 발송 이력)
  │
  └── audit_logs ─────────────────────────────────────────
        (변경 이력: 누가/언제/무엇을)
```

### 3.2 테이블 상세 설계

#### parishes
| Column | Type | Constraint | Note |
|--------|------|-----------|------|
| id | bigint | PK | |
| name | string | NOT NULL | 본당명 |
| address | string | | 주소 |
| phone | string | | 대표 전화 |
| created_at | datetime | | |
| updated_at | datetime | | |

#### users
| Column | Type | Constraint | Note |
|--------|------|-----------|------|
| id | bigint | PK | |
| parish_id | bigint | FK, NOT NULL | |
| email_address | string | UNIQUE, NOT NULL | Rails 8 인증 기본 컬럼명 |
| password_digest | string | NOT NULL | Rails 8 has_secure_password |
| role | string | NOT NULL, default: 'member' | admin/operator/member |
| name | string | NOT NULL | |
| created_at | datetime | | |
| updated_at | datetime | | |

#### sessions (Rails 8 빌트인)
| Column | Type | Constraint | Note |
|--------|------|-----------|------|
| id | bigint | PK | |
| user_id | bigint | FK, NOT NULL | |
| ip_address | string | | |
| user_agent | string | | |
| created_at | datetime | | |
| updated_at | datetime | | |

#### members
| Column | Type | Constraint | Note |
|--------|------|-----------|------|
| id | bigint | PK | |
| parish_id | bigint | FK, NOT NULL | |
| user_id | bigint | FK, UNIQUE | 1:1 (선택적) |
| name | string | NOT NULL | |
| baptismal_name | string | | 세례명 |
| phone | string | | 마스킹 대상 |
| email | string | | |
| birth_date | date | | 마스킹 대상 |
| gender | string | | |
| district | string | | 구역 |
| group_name | string | | 단체명 |
| baptized | boolean | default: false | 세례 여부 |
| confirmed | boolean | default: false | 견진 여부 |
| active | boolean | default: true | 활성/비활성 |
| notes | text | | |
| created_at | datetime | | |
| updated_at | datetime | | |

#### roles
| Column | Type | Constraint | Note |
|--------|------|-----------|------|
| id | bigint | PK | |
| parish_id | bigint | FK, NOT NULL | |
| name | string | NOT NULL | 독서, 해설, 복사 등 |
| description | text | | |
| requires_baptism | boolean | default: false | |
| requires_confirmation | boolean | default: false | |
| min_age | integer | | |
| max_members | integer | | 최대 수행 가능 인원 |
| sort_order | integer | default: 0 | 표시 순서 |
| active | boolean | default: true | |
| created_at | datetime | | |
| updated_at | datetime | | |

#### event_types
| Column | Type | Constraint | Note |
|--------|------|-----------|------|
| id | bigint | PK | |
| parish_id | bigint | FK, NOT NULL | |
| name | string | NOT NULL | 주일미사, 평일미사 등 |
| description | text | | |
| default_time | time | | 기본 시간 |
| active | boolean | default: true | |
| created_at | datetime | | |
| updated_at | datetime | | |

#### event_role_requirements
| Column | Type | Constraint | Note |
|--------|------|-----------|------|
| id | bigint | PK | |
| event_type_id | bigint | FK, NOT NULL | |
| role_id | bigint | FK, NOT NULL | |
| required_count | integer | NOT NULL, default: 1 | 필요 인원수 |
| created_at | datetime | | |
| updated_at | datetime | | |
| | | UNIQUE(event_type_id, role_id) | |

#### events
| Column | Type | Constraint | Note |
|--------|------|-----------|------|
| id | bigint | PK | |
| parish_id | bigint | FK, NOT NULL | |
| event_type_id | bigint | FK, NOT NULL | |
| title | string | | 특별 행사명 |
| date | date | NOT NULL | |
| start_time | time | NOT NULL | |
| end_time | time | | |
| location | string | | |
| notes | text | | |
| recurring_group_id | string | | 반복 생성 그룹 ID |
| created_at | datetime | | |
| updated_at | datetime | | |

#### assignments
| Column | Type | Constraint | Note |
|--------|------|-----------|------|
| id | bigint | PK | |
| event_id | bigint | FK, NOT NULL | |
| role_id | bigint | FK, NOT NULL | |
| member_id | bigint | FK, NOT NULL | |
| status | string | NOT NULL, default: 'pending' | pending/accepted/declined/replaced/canceled |
| response_token | string | UNIQUE | 토큰 기반 수락/거절 |
| response_token_expires_at | datetime | | 토큰 만료 시간 |
| responded_at | datetime | | 응답 시각 |
| decline_reason | text | | 거절 사유 |
| replaced_by_id | bigint | FK | 대타 봉사자 |
| assigned_by_id | bigint | FK | 배정한 운영자 |
| created_at | datetime | | |
| updated_at | datetime | | |

#### attendance_records
| Column | Type | Constraint | Note |
|--------|------|-----------|------|
| id | bigint | PK | |
| event_id | bigint | FK, NOT NULL | |
| member_id | bigint | FK, NOT NULL | |
| assignment_id | bigint | FK | |
| status | string | NOT NULL | present/late/absent/excused/replaced |
| reason | text | | 사유 |
| recorded_by_id | bigint | FK | 입력한 운영자 |
| created_at | datetime | | |
| updated_at | datetime | | |
| | | UNIQUE(event_id, member_id) | |

#### availability_rules
| Column | Type | Constraint | Note |
|--------|------|-----------|------|
| id | bigint | PK | |
| member_id | bigint | FK, NOT NULL | |
| day_of_week | integer | | 0(일)~6(토) |
| event_type_id | bigint | FK | 특정 미사 유형만 |
| available | boolean | default: true | |
| max_per_month | integer | | 월 최대 봉사 횟수 |
| notes | text | | |
| created_at | datetime | | |
| updated_at | datetime | | |

#### blackout_periods
| Column | Type | Constraint | Note |
|--------|------|-----------|------|
| id | bigint | PK | |
| member_id | bigint | FK, NOT NULL | |
| start_date | date | NOT NULL | |
| end_date | date | NOT NULL | |
| reason | string | | 휴가/시험/출장 등 |
| created_at | datetime | | |
| updated_at | datetime | | |

#### qualifications
| Column | Type | Constraint | Note |
|--------|------|-----------|------|
| id | bigint | PK | |
| parish_id | bigint | FK, NOT NULL | |
| name | string | NOT NULL | 교육/자격명 |
| description | text | | |
| validity_months | integer | | 유효 기간 (월) |
| created_at | datetime | | |
| updated_at | datetime | | |

#### member_qualifications
| Column | Type | Constraint | Note |
|--------|------|-----------|------|
| id | bigint | PK | |
| member_id | bigint | FK, NOT NULL | |
| qualification_id | bigint | FK, NOT NULL | |
| acquired_date | date | NOT NULL | 취득일 |
| expires_date | date | | 만료일 |
| created_at | datetime | | |
| updated_at | datetime | | |

#### notifications
| Column | Type | Constraint | Note |
|--------|------|-----------|------|
| id | bigint | PK | |
| parish_id | bigint | FK, NOT NULL | |
| recipient_id | bigint | FK | member_id |
| sender_id | bigint | FK | user_id |
| notification_type | string | NOT NULL | assignment/reminder/announcement |
| channel | string | NOT NULL, default: 'email' | email/sms/push |
| subject | string | | |
| body | text | | |
| status | string | default: 'pending' | pending/sent/failed/read |
| sent_at | datetime | | |
| read_at | datetime | | |
| related_type | string | | polymorphic |
| related_id | bigint | | polymorphic |
| created_at | datetime | | |
| updated_at | datetime | | |

#### audit_logs
| Column | Type | Constraint | Note |
|--------|------|-----------|------|
| id | bigint | PK | |
| parish_id | bigint | FK | |
| user_id | bigint | FK | 변경한 사용자 |
| action | string | NOT NULL | create/update/destroy |
| auditable_type | string | NOT NULL | polymorphic |
| auditable_id | bigint | NOT NULL | polymorphic |
| changes_data | jsonb | | 변경 내용 |
| ip_address | string | | |
| user_agent | string | | |
| created_at | datetime | NOT NULL | updated_at 없음 (불변) |

### 3.3 인덱스 전략

```ruby
# 자주 사용되는 쿼리 기반 인덱스
add_index :members, :parish_id
add_index :members, [:parish_id, :active]
add_index :members, :user_id, unique: true

add_index :events, :parish_id
add_index :events, [:parish_id, :date]
add_index :events, :event_type_id
add_index :events, :recurring_group_id

add_index :assignments, :event_id
add_index :assignments, :member_id
add_index :assignments, :role_id
add_index :assignments, [:event_id, :role_id, :member_id], unique: true
add_index :assignments, :response_token, unique: true
add_index :assignments, :status

add_index :attendance_records, [:event_id, :member_id], unique: true
add_index :attendance_records, :member_id

add_index :audit_logs, [:auditable_type, :auditable_id]
add_index :audit_logs, :user_id
add_index :audit_logs, :created_at
```

---

## 4. Gemfile 구성

```ruby
source "https://rubygems.org"

gem "rails", "~> 8.0"
gem "pg", "~> 1.5"
gem "puma", ">= 5"
gem "propshaft"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "solid_queue"
gem "solid_cache"
gem "solid_cable"
gem "thruster"
gem "pundit"
gem "bcrypt", "~> 3.1"
gem "jbuilder"
gem "bootsnap", require: false
gem "kamal", require: false  # Railway 사용하지만 참조용

group :development, :test do
  gem "debug", platforms: %i[mri windows], require: "debug/prelude"
  gem "rspec-rails", "~> 7.0"
  gem "factory_bot_rails"
  gem "faker"
  gem "brakeman", require: false
  gem "rubocop-rails-omakase", require: false
end

group :test do
  gem "shoulda-matchers"
  gem "capybara"
  gem "selenium-webdriver"
  gem "simplecov", require: false
  gem "database_cleaner-active_record"
  gem "pundit-matchers"
end

group :development do
  gem "web-console"
  gem "hotwire-livereload"
end
```

---

## 5. Railway 배포 설정

### 5.1 Procfile

```
web: bundle exec thrust bundle exec puma -C config/puma.rb
```

### 5.2 필요 환경변수

| Variable | Purpose | Railway 설정 |
|----------|---------|-------------|
| `DATABASE_URL` | PostgreSQL 연결 | Postgres addon 자동 제공 |
| `SECRET_KEY_BASE` | Rails 시크릿 | `bin/rails secret`으로 생성 |
| `RAILS_ENV` | 환경 | `production` |
| `RAILS_SERVE_STATIC_FILES` | 정적 파일 서빙 | `true` (Thruster 사용) |
| `SMTP_ADDRESS` | 이메일 서버 | 별도 설정 |
| `SMTP_PORT` | 이메일 포트 | 별도 설정 |
| `SMTP_USERNAME` | 이메일 사용자 | 별도 설정 |
| `SMTP_PASSWORD` | 이메일 비밀번호 | 별도 설정 |

### 5.3 Redis 불필요

Rails 8의 Solid Trifecta (Solid Queue + Solid Cache + Solid Cable)는 모두 PostgreSQL을
백엔드로 사용합니다. 따라서 Railway에서 Redis 서비스를 추가할 필요가 없습니다.

---

## 6. CI 설정 (GitHub Actions)

```yaml
# .github/workflows/ci.yml
name: CI
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    services:
      postgres:
        image: postgres:16
        env:
          POSTGRES_PASSWORD: postgres
        options: >-
          --health-cmd pg_isready
          --health-interval 10s
          --health-timeout 5s
          --health-retries 5
        ports:
          - 5432:5432

    steps:
      - uses: actions/checkout@v4
      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.2'
          bundler-cache: true
      - name: Setup DB
        env:
          DATABASE_URL: postgres://postgres:postgres@localhost:5432/test
          RAILS_ENV: test
        run: bin/rails db:setup
      - name: Run RSpec
        env:
          DATABASE_URL: postgres://postgres:postgres@localhost:5432/test
          RAILS_ENV: test
        run: bundle exec rspec
      - name: Run RuboCop
        run: bundle exec rubocop
      - name: Run Brakeman
        run: bundle exec brakeman -q
```

---

## 7. Seed Data

```ruby
# db/seeds.rb

# 기본 본당
parish = Parish.find_or_create_by!(name: "성산성당") do |p|
  p.address = "서울시 마포구"
end

# 기본 역할
roles = [
  { name: "독서1", sort_order: 1 },
  { name: "독서2", sort_order: 2 },
  { name: "해설", sort_order: 3 },
  { name: "복사", sort_order: 4, requires_baptism: true },
  { name: "성가", sort_order: 5 },
  { name: "봉헌", sort_order: 6 },
  { name: "제대회", sort_order: 7, requires_confirmation: true },
]

roles.each do |role_attrs|
  Role.find_or_create_by!(parish: parish, name: role_attrs[:name]) do |r|
    r.assign_attributes(role_attrs)
  end
end

# 기본 미사 유형
event_types = [
  { name: "주일미사(1차)", default_time: "07:00" },
  { name: "주일미사(2차)", default_time: "09:00" },
  { name: "주일미사(3차)", default_time: "11:00" },
  { name: "주일미사(4차)", default_time: "17:00" },
  { name: "평일미사", default_time: "06:30" },
  { name: "토요미사", default_time: "16:00" },
  { name: "대축일미사", default_time: "10:00" },
]

event_types.each do |et_attrs|
  EventType.find_or_create_by!(parish: parish, name: et_attrs[:name]) do |et|
    et.assign_attributes(et_attrs)
  end
end
```

---

## 8. Success Criteria

### 8.1 Definition of Done

- [ ] `rails new` 완료 (PostgreSQL, Rails 8)
- [ ] 15개 핵심 테이블 마이그레이션 생성 및 실행
- [ ] 모든 모델 관계(belongs_to, has_many) 설정
- [ ] 모든 모델 기본 유효성 검증 설정
- [ ] Concerns 3개 생성 (Auditable, ParishScoped, Maskable)
- [ ] Seed 데이터 실행 성공
- [ ] RSpec 기본 설정 완료
- [ ] Model specs 작성 (관계, 유효성)
- [ ] RuboCop 설정 및 lint 통과
- [ ] GitHub Actions CI 통과
- [ ] Procfile 생성

### 8.2 Quality Criteria

- [ ] `bin/rails db:migrate` 성공
- [ ] `bin/rails db:seed` 성공
- [ ] `bundle exec rspec` 통과
- [ ] `bundle exec rubocop` 통과
- [ ] `bundle exec brakeman` Critical 0

---

## 9. Risks and Mitigation

| Risk | Impact | Likelihood | Mitigation |
|------|--------|------------|------------|
| Rails 8 gem 호환성 | Medium | Low | Gemfile에서 버전 제약 명시, 호환성 확인 |
| PostgreSQL 16 Railway 지원 | Low | Low | Railway는 PostgreSQL 16 지원 |
| Solid Queue 안정성 | Medium | Low | PostgreSQL FOR UPDATE SKIP LOCKED 기반, 검증됨 |
| Import Maps 제한 | Low | Medium | 필요 시 jsbundling-rails로 전환 가능 |

---

## 10. Next Steps

1. [ ] 이 Plan 문서 승인
2. [ ] `/pdca design F01-bootstrap` - Design 문서 작성
3. [ ] `/pdca do F01-bootstrap` - 구현 시작

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | 2026-02-16 | Initial F01 plan (Rails 8) | CTO Lead |
