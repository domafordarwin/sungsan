# F01: Project Bootstrap & DB Schema - Design Document

> **Summary**: Rails 8 프로젝트 초기화 및 15개 핵심 테이블 DB 스키마 설계 상세
>
> **Project**: AltarServe Manager (성단 매니저)
> **Version**: 0.1.0
> **Author**: CTO Lead (Architect)
> **Date**: 2026-02-16
> **Status**: Draft
> **Planning Doc**: [F01-bootstrap.plan.md](../../01-plan/features/F01-bootstrap.plan.md)

### Pipeline References

| Phase | Document | Status |
|-------|----------|--------|
| Phase 1 | [Schema Definition](../../01-plan/features/F01-bootstrap.plan.md#3-database-schema) | Plan 문서 내 포함 |
| Phase 2 | [Coding Conventions](../../01-plan/03-conventions.md) | Approved |

---

## 1. Overview

### 1.1 Design Goals

1. Rails 8 프로젝트를 PostgreSQL 기반으로 생성
2. 15개 핵심 테이블의 마이그레이션을 올바른 순서로 생성/실행
3. 모든 모델에 관계, 유효성, 인덱스를 정확히 설정
4. 3개 공통 Concerns (Auditable, ParishScoped, Maskable) 구현
5. 개발용 Seed 데이터 구성
6. RSpec + RuboCop + Brakeman + CI 기본 설정

### 1.2 Design Principles

- **Convention over Configuration**: Rails 8 기본 설정 최대한 활용
- **Solid Trifecta First**: Redis 없이 Solid Queue/Cache/Cable 사용
- **Parish Scope**: 멀티 본당 대비하여 모든 쿼리에 parish_id 스코프 적용
- **Audit by Default**: CUD 작업에 자동 감사로그 기록
- **Privacy by Design**: 개인정보 필드에 마스킹 메커니즘 내장

---

## 2. Architecture

### 2.1 Rails 8 프로젝트 생성 명령

```bash
rails new sungsan \
  --database=postgresql \
  --css=tailwind \
  --skip-test \
  --skip-jbuilder
```

**옵션 설명**:
- `--database=postgresql`: PostgreSQL 사용
- `--css=tailwind`: Tailwind CSS (Import Maps 호환)
- `--skip-test`: Minitest 스킵 (RSpec 사용)
- `--skip-jbuilder`: JSON builder 스킵 (API 응답은 직접 구성)

### 2.2 Rails 8 기본 포함 항목 (별도 설치 불필요)

| 항목 | 설명 |
|------|------|
| Propshaft | 에셋 파이프라인 |
| Import Maps | JS 모듈 관리 |
| Turbo Rails | Hotwire Turbo |
| Stimulus Rails | Hotwire Stimulus |
| Solid Queue | 백그라운드 잡 |
| Solid Cache | 캐싱 |
| Solid Cable | WebSocket |
| Thruster | 웹서버 프록시 |
| Puma | 웹서버 |

### 2.3 Layer Architecture

```
┌─────────────────────────────────────────────────────────┐
│ Presentation Layer                                       │
│   Controllers (app/controllers/)                         │
│   Views + Turbo Frames/Streams (app/views/)             │
│   Stimulus Controllers (app/javascript/controllers/)     │
├─────────────────────────────────────────────────────────┤
│ Application Layer                                        │
│   Service Objects (app/services/)                        │
│   Pundit Policies (app/policies/)                        │
│   Solid Queue Jobs (app/jobs/)                           │
│   Mailers (app/mailers/)                                 │
├─────────────────────────────────────────────────────────┤
│ Domain Layer                                             │
│   Models + ActiveRecord (app/models/)                    │
│   Concerns (app/models/concerns/)                        │
│   Validations, Callbacks, Scopes                         │
├─────────────────────────────────────────────────────────┤
│ Infrastructure Layer                                     │
│   PostgreSQL (Solid Queue/Cache/Cable 포함)              │
│   Email (Action Mailer)                                  │
│   File Storage (Active Storage - 향후)                   │
└─────────────────────────────────────────────────────────┘
```

### 2.4 Dependencies (F01 범위)

| Component | Depends On | Purpose |
|-----------|-----------|---------|
| Models | PostgreSQL | 데이터 저장 |
| Concerns | Models | 횡단 관심사 |
| Factories | Models | 테스트 데이터 |
| Seeds | Models | 개발 데이터 |
| CI | RSpec, RuboCop, Brakeman | 자동 품질 검증 |

---

## 3. Migration Order (의존성 기반)

마이그레이션은 FK 의존성을 고려하여 아래 순서로 생성합니다.

### 3.1 Phase 1: Independent Tables (의존성 없음)

```
001_create_parishes.rb
```

### 3.2 Phase 2: Parish-dependent Tables

```
002_create_users.rb          (-> parishes)
003_create_roles.rb          (-> parishes)
004_create_event_types.rb    (-> parishes)
005_create_qualifications.rb (-> parishes)
```

### 3.3 Phase 3: User/Role-dependent Tables

```
006_create_members.rb               (-> parishes, users)
007_create_event_role_requirements.rb (-> event_types, roles)
008_create_events.rb                 (-> parishes, event_types)
```

### 3.4 Phase 4: Member-dependent Tables

```
009_create_availability_rules.rb     (-> members, event_types)
010_create_blackout_periods.rb       (-> members)
011_create_member_qualifications.rb  (-> members, qualifications)
```

### 3.5 Phase 5: Event-dependent Tables

```
012_create_assignments.rb            (-> events, roles, members)
013_create_attendance_records.rb     (-> events, members, assignments)
```

### 3.6 Phase 6: System Tables

```
014_create_notifications.rb          (-> parishes, members, users)
015_create_audit_logs.rb             (polymorphic, -> parishes, users)
```

### 3.7 Phase 7: Rails 8 Solid Infrastructure

```
016_create_solid_queue_tables.rb     (Solid Queue 설치 시 자동 생성)
017_create_solid_cache_tables.rb     (Solid Cache 설치 시 자동 생성)
018_create_solid_cable_tables.rb     (Solid Cable 설치 시 자동 생성)
```

---

## 4. Model Design

### 4.1 Model Relationships (ERD)

```
Parish
  has_many :users
  has_many :members
  has_many :roles
  has_many :event_types
  has_many :qualifications
  has_many :events
  has_many :notifications
  has_many :audit_logs

User
  belongs_to :parish
  has_one    :member
  has_many   :sessions          # Rails 8 빌트인 인증

Member
  belongs_to :parish
  belongs_to :user, optional: true
  has_many   :assignments
  has_many   :attendance_records
  has_many   :availability_rules
  has_many   :blackout_periods
  has_many   :member_qualifications
  has_many   :qualifications, through: :member_qualifications

Role
  belongs_to :parish
  has_many   :event_role_requirements
  has_many   :assignments

EventType
  belongs_to :parish
  has_many   :event_role_requirements
  has_many   :roles, through: :event_role_requirements
  has_many   :events

EventRoleRequirement
  belongs_to :event_type
  belongs_to :role

Event
  belongs_to :parish
  belongs_to :event_type
  has_many   :assignments
  has_many   :attendance_records

Assignment
  belongs_to :event
  belongs_to :role
  belongs_to :member
  belongs_to :replaced_by, class_name: 'Member', optional: true
  belongs_to :assigned_by, class_name: 'User', optional: true
  has_one    :attendance_record

AttendanceRecord
  belongs_to :event
  belongs_to :member
  belongs_to :assignment, optional: true
  belongs_to :recorded_by, class_name: 'User', optional: true

AvailabilityRule
  belongs_to :member
  belongs_to :event_type, optional: true

BlackoutPeriod
  belongs_to :member

Qualification
  belongs_to :parish
  has_many   :member_qualifications

MemberQualification
  belongs_to :member
  belongs_to :qualification

Notification
  belongs_to :parish
  belongs_to :recipient, class_name: 'Member', optional: true
  belongs_to :sender, class_name: 'User', optional: true
  belongs_to :related, polymorphic: true, optional: true

AuditLog
  belongs_to :parish, optional: true
  belongs_to :user, optional: true
  belongs_to :auditable, polymorphic: true
```

### 4.2 Validations

```ruby
# Parish
validates :name, presence: true, uniqueness: true

# User
validates :email_address, presence: true, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
validates :name, presence: true
validates :role, presence: true, inclusion: { in: %w[admin operator member] }

# Member
validates :name, presence: true
validates :user_id, uniqueness: true, allow_nil: true
validates :phone, format: { with: /\A\d{2,3}-\d{3,4}-\d{4}\z/ }, allow_blank: true

# Role
validates :name, presence: true, uniqueness: { scope: :parish_id }
validates :sort_order, numericality: { only_integer: true, greater_than_or_equal_to: 0 }

# EventType
validates :name, presence: true, uniqueness: { scope: :parish_id }

# EventRoleRequirement
validates :required_count, presence: true, numericality: { only_integer: true, greater_than: 0 }
validates :role_id, uniqueness: { scope: :event_type_id }

# Event
validates :date, presence: true
validates :start_time, presence: true

# Assignment
validates :status, presence: true, inclusion: { in: %w[pending accepted declined replaced canceled] }
validates :member_id, uniqueness: { scope: [:event_id, :role_id], message: '이미 같은 역할에 배정되어 있습니다' }
validates :response_token, uniqueness: true, allow_nil: true

# AttendanceRecord
validates :status, presence: true, inclusion: { in: %w[present late absent excused replaced] }
validates :member_id, uniqueness: { scope: :event_id, message: '이미 출결이 기록되어 있습니다' }

# AvailabilityRule
validates :day_of_week, inclusion: { in: 0..6 }, allow_nil: true

# BlackoutPeriod
validates :start_date, presence: true
validates :end_date, presence: true
validate :end_date_after_start_date

# Qualification
validates :name, presence: true, uniqueness: { scope: :parish_id }

# MemberQualification
validates :acquired_date, presence: true
validates :qualification_id, uniqueness: { scope: :member_id }

# Notification
validates :notification_type, presence: true, inclusion: { in: %w[assignment reminder announcement] }
validates :channel, presence: true, inclusion: { in: %w[email sms push] }
validates :status, inclusion: { in: %w[pending sent failed read] }

# AuditLog
validates :action, presence: true, inclusion: { in: %w[create update destroy] }
validates :auditable_type, presence: true
validates :auditable_id, presence: true
```

### 4.3 Scopes

```ruby
# Member
scope :active, -> { where(active: true) }
scope :inactive, -> { where(active: false) }
scope :baptized, -> { where(baptized: true) }
scope :confirmed, -> { where(confirmed: true) }
scope :by_district, ->(district) { where(district: district) }

# Event
scope :upcoming, -> { where('date >= ?', Date.current).order(:date, :start_time) }
scope :past, -> { where('date < ?', Date.current).order(date: :desc) }
scope :on_date, ->(date) { where(date: date) }
scope :this_week, -> { where(date: Date.current.beginning_of_week..Date.current.end_of_week) }
scope :this_month, -> { where(date: Date.current.beginning_of_month..Date.current.end_of_month) }

# Assignment
scope :pending, -> { where(status: 'pending') }
scope :accepted, -> { where(status: 'accepted') }
scope :declined, -> { where(status: 'declined') }
scope :for_member, ->(member) { where(member: member) }
scope :for_event, ->(event) { where(event: event) }
scope :for_role, ->(role) { where(role: role) }

# AttendanceRecord
scope :present_or_late, -> { where(status: %w[present late]) }

# BlackoutPeriod
scope :active_on, ->(date) { where('start_date <= ? AND end_date >= ?', date, date) }

# AuditLog
scope :recent, -> { order(created_at: :desc).limit(100) }
scope :for_record, ->(type, id) { where(auditable_type: type, auditable_id: id) }
```

---

## 5. Concerns Design

### 5.1 ParishScoped

모든 parish 종속 모델에 적용. 쿼리 시 자동으로 현재 parish로 필터링.

```ruby
# app/models/concerns/parish_scoped.rb
module ParishScoped
  extend ActiveSupport::Concern

  included do
    belongs_to :parish
    validates :parish_id, presence: true

    # Current.parish가 설정되어 있으면 자동 스코프 적용
    default_scope -> { where(parish_id: Current.parish_id) if Current.parish_id }
  end

  class_methods do
    def unscoped_by_parish
      unscope(where: :parish_id)
    end
  end
end
```

```ruby
# app/models/current.rb (Rails 8 Current Attributes)
class Current < ActiveSupport::CurrentAttributes
  attribute :user
  attribute :parish_id

  def parish
    Parish.find(parish_id) if parish_id
  end
end
```

**적용 모델**: Parish 자체를 제외한 모든 모델 (users, members, roles, event_types, events, qualifications, notifications)

### 5.2 Auditable

CUD 작업 시 자동으로 audit_logs에 기록.

```ruby
# app/models/concerns/auditable.rb
module Auditable
  extend ActiveSupport::Concern

  included do
    after_create  { log_audit('create') }
    after_update  { log_audit('update') }
    after_destroy { log_audit('destroy') }
  end

  private

  def log_audit(action)
    AuditLog.create!(
      parish_id: try(:parish_id) || Current.parish_id,
      user_id: Current.user&.id,
      action: action,
      auditable: self,
      changes_data: action == 'create' ? attributes : saved_changes.except('updated_at'),
      ip_address: Current.try(:ip_address),
      user_agent: Current.try(:user_agent)
    )
  rescue StandardError => e
    Rails.logger.error("Audit log failed: #{e.message}")
    # 감사로그 실패가 본 작업을 중단시키지 않도록
  end
end
```

**적용 모델**: members, assignments, attendance_records, roles, events, event_role_requirements, member_qualifications

### 5.3 Maskable

개인정보 필드를 역할에 따라 마스킹.

```ruby
# app/models/concerns/maskable.rb
module Maskable
  extend ActiveSupport::Concern

  class_methods do
    def maskable_fields(*fields)
      @maskable_fields = fields
      fields.each do |field|
        define_method("masked_#{field}") do
          Maskable.mask_value(field, send(field), Current.user)
        end
      end
    end

    def get_maskable_fields
      @maskable_fields || []
    end
  end

  def self.mask_value(field, value, current_user)
    return value if value.blank?
    return value if current_user&.admin?

    case field
    when :phone
      mask_phone(value)
    when :email
      mask_email(value)
    when :birth_date
      mask_date(value)
    else
      '***'
    end
  end

  def self.mask_phone(phone)
    return phone if phone.blank?
    phone.gsub(/(\d{3})-(\d{3,4})-(\d{4})/, '\1-****-\3')
  end

  def self.mask_email(email)
    return email if email.blank?
    local, domain = email.split('@')
    "#{local[0..1]}***@#{domain}"
  end

  def self.mask_date(date)
    return date if date.blank?
    date.strftime('%Y-**-**')
  end
end
```

**적용 모델**: Member (phone, email, birth_date)

---

## 6. Seed Data Design

```ruby
# db/seeds.rb
puts "Seeding AltarServe Manager..."

# 1. 기본 본당
parish = Parish.find_or_create_by!(name: "성산성당") do |p|
  p.address = "서울시 마포구 성산동"
  p.phone = "02-123-4567"
end

# 2. 관리자 계정 (Rails 8 빌트인 인증)
admin = User.find_or_create_by!(email_address: "admin@sungsan.org") do |u|
  u.parish = parish
  u.name = "관리자"
  u.password = "password123"
  u.role = "admin"
end

# 3. 역할 정의
roles_data = [
  { name: "독서1", sort_order: 1 },
  { name: "독서2", sort_order: 2 },
  { name: "해설", sort_order: 3 },
  { name: "복사", sort_order: 4, requires_baptism: true },
  { name: "성가", sort_order: 5 },
  { name: "봉헌", sort_order: 6 },
  { name: "제대회", sort_order: 7, requires_confirmation: true },
]
roles = roles_data.map do |attrs|
  Role.find_or_create_by!(parish: parish, name: attrs[:name]) do |r|
    r.assign_attributes(attrs)
  end
end

# 4. 미사 유형
event_types_data = [
  { name: "주일미사(1차)", default_time: "07:00" },
  { name: "주일미사(2차)", default_time: "09:00" },
  { name: "주일미사(3차)", default_time: "11:00" },
  { name: "주일미사(4차)", default_time: "17:00" },
  { name: "평일미사", default_time: "06:30" },
  { name: "토요미사", default_time: "16:00" },
  { name: "대축일미사", default_time: "10:00" },
]
event_types = event_types_data.map do |attrs|
  EventType.find_or_create_by!(parish: parish, name: attrs[:name]) do |et|
    et.assign_attributes(attrs)
  end
end

# 5. 미사유형별 역할 요구사항 (주일미사 3차 예시)
sunday_3rd = event_types.find { |et| et.name == "주일미사(3차)" }
[
  { role: "독서1", count: 1 },
  { role: "독서2", count: 1 },
  { role: "해설", count: 1 },
  { role: "복사", count: 4 },
  { role: "성가", count: 2 },
  { role: "봉헌", count: 2 },
  { role: "제대회", count: 2 },
].each do |req|
  role = roles.find { |r| r.name == req[:role] }
  EventRoleRequirement.find_or_create_by!(event_type: sunday_3rd, role: role) do |err|
    err.required_count = req[:count]
  end
end

# 6. 자격/교육 정의
qualifications_data = [
  { name: "복사 교육", validity_months: 12 },
  { name: "독서 교육", validity_months: nil },
  { name: "안전 교육", validity_months: 12 },
]
qualifications_data.each do |attrs|
  Qualification.find_or_create_by!(parish: parish, name: attrs[:name]) do |q|
    q.assign_attributes(attrs)
  end
end

# 7. 개발용 테스트 봉사자 (development 환경만)
if Rails.env.development?
  10.times do |i|
    member = Member.find_or_create_by!(parish: parish, name: "봉사자#{i + 1}") do |m|
      m.phone = "010-#{rand(1000..9999)}-#{rand(1000..9999)}"
      m.baptismal_name = ["베드로", "바오로", "요한", "마리아", "안나", "요셉", "프란치스코", "데레사", "아녜스", "루치아"][i]
      m.district = "#{rand(1..10)}구역"
      m.baptized = true
      m.confirmed = i < 7
      m.active = true
    end
  end
end

puts "Seeding completed!"
```

---

## 7. Test Plan (F01 범위)

### 7.1 Test Scope

| Type | Target | Tool | Coverage Target |
|------|--------|------|:-:|
| Model Spec | 15개 모델 관계/유효성/스코프 | RSpec + Shoulda | 90% |
| Concern Spec | ParishScoped, Auditable, Maskable | RSpec | 95% |
| Factory Spec | 15개 팩토리 정상 생성 | FactoryBot | 100% |

### 7.2 Test Cases

#### Model Specs (핵심)

```ruby
# spec/models/parish_spec.rb
RSpec.describe Parish do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name) }
  end

  describe 'associations' do
    it { is_expected.to have_many(:users) }
    it { is_expected.to have_many(:members) }
    it { is_expected.to have_many(:roles) }
    it { is_expected.to have_many(:event_types) }
    it { is_expected.to have_many(:events) }
  end
end

# spec/models/assignment_spec.rb
RSpec.describe Assignment do
  describe 'validations' do
    it { is_expected.to validate_presence_of(:status) }
    it { is_expected.to validate_inclusion_of(:status).in_array(%w[pending accepted declined replaced canceled]) }
    it { is_expected.to validate_uniqueness_of(:member_id).scoped_to([:event_id, :role_id]) }
    it { is_expected.to validate_uniqueness_of(:response_token).allow_nil }
  end

  describe 'associations' do
    it { is_expected.to belong_to(:event) }
    it { is_expected.to belong_to(:role) }
    it { is_expected.to belong_to(:member) }
  end
end
```

#### Concern Specs

```ruby
# spec/models/concerns/auditable_spec.rb
RSpec.describe Auditable do
  let(:member) { create(:member) }

  it 'creates audit log on create' do
    expect { member }.to change(AuditLog, :count).by(1)
    expect(AuditLog.last.action).to eq('create')
  end

  it 'creates audit log on update' do
    member
    expect { member.update!(name: 'New Name') }.to change(AuditLog, :count).by(1)
    expect(AuditLog.last.action).to eq('update')
  end
end

# spec/models/concerns/maskable_spec.rb
RSpec.describe Maskable do
  it 'masks phone number' do
    expect(Maskable.mask_phone('010-1234-5678')).to eq('010-****-5678')
  end

  it 'masks email' do
    expect(Maskable.mask_email('user@example.com')).to eq('us***@example.com')
  end
end
```

### 7.3 Factory List

| Factory | Key Attributes | Traits |
|---------|---------------|--------|
| parish | name | |
| user | email_address, name, role, parish | :admin, :operator, :member |
| member | name, parish | :active, :inactive, :baptized, :confirmed |
| role | name, parish | :requires_baptism, :requires_confirmation |
| event_type | name, parish | |
| event_role_requirement | event_type, role, required_count | |
| event | date, start_time, event_type, parish | :upcoming, :past |
| assignment | event, role, member | :pending, :accepted, :declined |
| attendance_record | event, member, status | :present, :late, :absent |
| availability_rule | member | |
| blackout_period | member, start_date, end_date | |
| qualification | name, parish | |
| member_qualification | member, qualification | |
| notification | parish, notification_type, channel | |
| audit_log | action, auditable | |

---

## 8. Configuration Files

### 8.1 .rubocop.yml

```yaml
inherit_gem:
  rubocop-rails-omakase: rubocop.yml

AllCops:
  TargetRubyVersion: 3.2
  NewCops: enable
  Exclude:
    - 'db/schema.rb'
    - 'bin/**/*'
    - 'vendor/**/*'
    - 'node_modules/**/*'

Style/Documentation:
  Enabled: false

Metrics/BlockLength:
  Exclude:
    - 'spec/**/*'
    - 'config/routes.rb'

Metrics/MethodLength:
  Max: 20
```

### 8.2 config/database.yml

```yaml
default: &default
  adapter: postgresql
  encoding: unicode
  pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>

development:
  <<: *default
  database: sungsan_development

test:
  <<: *default
  database: sungsan_test

production:
  <<: *default
  url: <%= ENV["DATABASE_URL"] %>
```

### 8.3 Procfile (Railway)

```
web: bundle exec thrust bundle exec puma -C config/puma.rb
```

### 8.4 GitHub Actions CI

```yaml
name: CI
on: [push, pull_request]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.2'
          bundler-cache: true
      - run: bundle exec rubocop
      - run: bundle exec brakeman -q --no-pager

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
    env:
      DATABASE_URL: postgres://postgres:postgres@localhost:5432/sungsan_test
      RAILS_ENV: test
    steps:
      - uses: actions/checkout@v4
      - uses: ruby/setup-ruby@v1
        with:
          ruby-version: '3.2'
          bundler-cache: true
      - run: bin/rails db:create db:migrate
      - run: bundle exec rspec --format documentation
```

---

## 9. Implementation Order

### 9.1 Step-by-step Checklist

```
Phase A: 프로젝트 생성 (30분)
  1. [ ] rails new sungsan --database=postgresql --css=tailwind --skip-test --skip-jbuilder
  2. [ ] Gemfile 수정 (RSpec, FactoryBot, Pundit, SimpleCov 등 추가)
  3. [ ] bundle install
  4. [ ] bin/rails generate rspec:install
  5. [ ] spec/rails_helper.rb 설정 (FactoryBot, Shoulda, DatabaseCleaner)

Phase B: 마이그레이션 생성 (1시간)
  6. [ ] 001_create_parishes
  7. [ ] 002_create_users (+ sessions)
  8. [ ] 003_create_roles
  9. [ ] 004_create_event_types
  10. [ ] 005_create_qualifications
  11. [ ] 006_create_members
  12. [ ] 007_create_event_role_requirements
  13. [ ] 008_create_events
  14. [ ] 009_create_availability_rules
  15. [ ] 010_create_blackout_periods
  16. [ ] 011_create_member_qualifications
  17. [ ] 012_create_assignments
  18. [ ] 013_create_attendance_records
  19. [ ] 014_create_notifications
  20. [ ] 015_create_audit_logs
  21. [ ] bin/rails db:create db:migrate

Phase C: 모델 생성 (1시간)
  22. [ ] 15개 모델 파일 생성 (관계, 유효성, 스코프)
  23. [ ] Current 모델 설정
  24. [ ] ParishScoped concern
  25. [ ] Auditable concern
  26. [ ] Maskable concern

Phase D: 테스트 & 설정 (1시간)
  27. [ ] 15개 Factory 생성
  28. [ ] 모델 스펙 작성 (관계, 유효성)
  29. [ ] Concern 스펙 작성
  30. [ ] Seed 데이터 작성
  31. [ ] bin/rails db:seed 실행 확인
  32. [ ] .rubocop.yml 설정
  33. [ ] .github/workflows/ci.yml 설정
  34. [ ] Procfile 생성
  35. [ ] bundle exec rspec 통과 확인
  36. [ ] bundle exec rubocop 통과 확인
  37. [ ] bundle exec brakeman 통과 확인
```

---

## 10. Security Considerations

- [x] SQL Injection: ActiveRecord parameterized queries 사용
- [x] Mass Assignment: Strong Parameters (컨트롤러 구현 시)
- [x] Sensitive Data: Maskable concern으로 phone/email/birth_date 마스킹
- [x] Audit Trail: Auditable concern으로 모든 CUD 기록
- [x] Password: Rails 8 has_secure_password (bcrypt)
- [ ] CSRF: 컨트롤러 구현 시 적용 (F02~)
- [ ] RBAC: Pundit 정책 구현 시 적용 (F02)

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | 2026-02-16 | Initial design document | CTO Lead (Architect) |
