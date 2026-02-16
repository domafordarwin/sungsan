# AltarServe Manager - QA Strategy (Reinforced)

> **Project**: AltarServe Manager (성단 매니저)
> **Date**: 2026-02-16
> **Status**: Approved
> **QA Level**: Enterprise Reinforced

---

## 1. QA Philosophy

이 프로젝트는 성당 운영에 직접 사용되는 시스템입니다.
배정 누락, 잘못된 알림, 권한 오류는 실제 전례 운영에 직접적 영향을 미칩니다.
따라서 QA를 단순 테스트가 아닌 **품질 보증 체계**로 접근합니다.

### 1.1 QA Principles

1. **Shift-Left Testing**: Design 단계부터 테스트 가능성 검증
2. **Continuous Verification**: 매 구현 단계마다 중간 검증
3. **Algorithm Regression**: 배정 알고리즘은 결정론적 테스트 필수
4. **Security by Default**: RBAC 테스트는 모든 Feature에 포함
5. **Performance Baseline**: 대규모 데이터에서의 성능 기준 확보

---

## 2. Testing Framework & Tools

| Tool | Purpose | Configuration |
|------|---------|---------------|
| RSpec | Unit/Integration 테스트 | `spec/` 디렉토리 |
| FactoryBot | 테스트 데이터 생성 | `spec/factories/` |
| Shoulda Matchers | 모델 매처 | ActiveRecord 관계/유효성 |
| Capybara | Feature/E2E 테스트 | Selenium/Rack::Test |
| SimpleCov | 커버리지 측정 | 목표: 80% 이상 |
| DatabaseCleaner | 테스트 DB 정리 | transaction strategy |
| Faker | 랜덤 테스트 데이터 | 한국어 로케일 포함 |
| Timecop/travel | 시간 관련 테스트 | 반복 일정, 리마인더 |

### Gemfile (test group)

```ruby
group :test do
  gem 'rspec-rails', '~> 4.0'
  gem 'factory_bot_rails'
  gem 'shoulda-matchers'
  gem 'capybara'
  gem 'selenium-webdriver'
  gem 'simplecov', require: false
  gem 'database_cleaner-active_record'
  gem 'faker'
  gem 'timecop'  # 또는 Rails 8 내장 travel_to 활용
  gem 'pundit-matchers'  # RBAC 테스트용
end
```

---

## 3. Test Categories & Coverage Targets

### 3.1 Unit Tests (Model Specs)

**목표 커버리지: 90%**

| Model | Test Focus | Priority |
|-------|-----------|----------|
| Member | 유효성, 관계, 스코프(active/inactive), 마스킹 | Critical |
| Event | 유효성, 반복 생성 로직, 시간 범위 검증 | Critical |
| Assignment | 상태 전이, 중복 방지, 자격 검증 | Critical |
| AttendanceRecord | 상태값, 통계 집계 정확도 | High |
| AvailabilityRule | 가용성 판단 로직 | High |
| BlackoutPeriod | 기간 겹침 검증 | Medium |
| Notification | 발송 상태, 채널별 처리 | Medium |
| AuditLog | 자동 기록, 변조 방지 | High |

### 3.2 Service Object Tests

**목표 커버리지: 95%**

| Service | Test Focus | Priority |
|---------|-----------|----------|
| AssignmentEngine | 필터링/스코어링/랭킹 정확도 | Critical |
| ScheduleGenerator | 반복 일정 생성 정확도 | Critical |
| SubstituteFinder | 대타 후보 추천 정확도 | High |
| AttendanceRecorder | 일괄 입력, 상태 정합성 | High |
| NotificationSender | 채널별 발송, 실패 처리 | Medium |
| StatisticsCalculator | 집계 정확도, 성능 | Medium |

### 3.3 Controller/Request Tests

**목표 커버리지: 85%**

| Area | Test Focus |
|------|-----------|
| Authentication | 로그인/로그아웃, 세션 관리 |
| Authorization | 역할별 접근 제어 (admin/operator/member) |
| CRUD Endpoints | 생성/조회/수정/삭제 정상 동작 |
| Error Handling | 잘못된 입력, 권한 없음, Not Found |
| Token Response | 토큰 기반 수락/거절 (만료, 재사용 방지) |

### 3.4 Feature/Integration Tests

**목표: 주요 사용자 플로우 100% 커버**

| Scenario | Steps | Assertions |
|----------|-------|------------|
| 관리자 플로우 | 로그인 -> 역할 설정 -> 일정 생성 -> 자동 배정 -> 알림 | 배정 완료, 알림 발송 |
| 운영자 플로우 | 로그인 -> 배정 수정 -> 출결 입력 -> 통계 확인 | 출결 기록, 통계 반영 |
| 봉사자 플로우 | 토큰 링크 -> 수락 -> 스케줄 확인 | 상태 변경, 스케줄 표시 |
| 대타 플로우 | 거절 -> 대타 요청 -> 대타 수락 | 상태 전이 완료 |
| 권한 위반 | member가 admin 기능 접근 | 403/redirect |

---

## 4. Algorithm-Specific Testing

배정 알고리즘은 시스템의 핵심이므로 별도의 심층 테스트 전략을 적용합니다.

### 4.1 Deterministic Test Data Set

```ruby
# spec/fixtures/assignment_scenarios.yml
# 고정된 시나리오 데이터로 결정론적 테스트

scenario_fair_rotation:
  members: 10
  events: 4 (weekly)
  roles: [독서1, 독서2, 해설, 복사x2]
  expected: 각 봉사자 균등 배정 (표준편차 < 1.0)

scenario_qualification_filter:
  members: 10 (3명만 복사 자격)
  event: 주일미사
  role: 복사
  expected: 자격 보유 3명 중에서만 배정

scenario_blackout_respect:
  members: 5
  blackout: member_1 (이번 주 휴가)
  expected: member_1 제외

scenario_conflict_prevention:
  members: 5
  events: 2 (동시간)
  expected: 동일인 중복 배정 없음

scenario_preference_boost:
  members: 5
  preferences: member_1 (주일 오전 선호)
  expected: member_1이 주일 오전에 우선 배정
```

### 4.2 Regression Test Suite

```ruby
# spec/services/assignment_engine_spec.rb

RSpec.describe AssignmentEngine do
  describe '#recommend' do
    context '공정성 (fairness)' do
      it '10명 봉사자, 4주 배정 시 표준편차 < 1.0'
      it '최근 배정된 봉사자가 다음 배정에서 후순위'
    end

    context '자격 필터링 (qualification)' do
      it '자격 미달 봉사자를 후보에서 제외'
      it '복수 자격이 필요한 역할에 대해 모두 충족하는 후보만 포함'
    end

    context '가용성 (availability)' do
      it 'blackout 기간 봉사자 제외'
      it '가용 요일이 맞지 않는 봉사자 제외'
      it '동시간 이미 배정된 봉사자 제외'
    end

    context '스코어링 (scoring)' do
      it '최근 수행 횟수가 적은 봉사자가 높은 순위'
      it '선호도 보너스가 정확히 반영됨'
      it '거절/결석 패널티가 정확히 반영됨'
    end

    context '엣지 케이스' do
      it '후보가 부족할 때 부분 배정 + 경고'
      it '후보가 0명일 때 빈 결과 + 에러 없음'
      it '가중치 0일 때 해당 요소 무시'
    end
  end
end
```

### 4.3 Algorithm Performance Benchmark

```ruby
# spec/benchmarks/assignment_benchmark_spec.rb

RSpec.describe 'Assignment Performance' do
  context '소규모 본당 (200명)' do
    it '배정 추천 < 500ms'
  end

  context '대규모 본당 (2000명)' do
    it '배정 추천 < 2000ms'
  end

  context '한 달 전체 배정 (200명, 20 이벤트)' do
    it '전체 배정 < 10000ms'
  end
end
```

---

## 5. Security Testing Matrix

### 5.1 RBAC Penetration Tests

| Test Case | Expected |
|-----------|----------|
| member가 /admin/* 접근 | 403 or redirect |
| operator가 parish 설정 변경 시도 | 403 |
| member가 타인의 개인정보 조회 | 마스킹 적용 or 403 |
| 만료된 토큰으로 수락/거절 시도 | 401 |
| 이미 사용된 토큰 재사용 | 400 |
| 비인증 사용자가 API 접근 | 401 or redirect |
| operator가 감사로그 삭제 시도 | 403 (삭제 불가) |

### 5.2 Data Protection Tests

| Test Case | Expected |
|-----------|----------|
| 연락처 마스킹 (operator 조회) | 010-****-5678 형태 |
| 연락처 마스킹 (member 조회) | 타인 정보 완전 마스킹 |
| 감사로그 기록 | 모든 CUD 작업에 로그 |
| SQL Injection 방지 | 파라미터 바인딩 확인 |
| XSS 방지 | 출력 이스케이핑 확인 |
| CSRF 보호 | 토큰 검증 확인 |

---

## 6. Gap Analysis Protocol (Check Phase)

### 6.1 Analysis Dimensions

| Dimension | Weight | Description |
|-----------|--------|-------------|
| Functional Completeness | 30% | PRD 요구사항 구현 완료도 |
| Design Conformance | 25% | Design 문서와 구현 일치도 |
| Test Coverage | 20% | 코드 커버리지 + 테스트 품질 |
| Security Compliance | 15% | RBAC, 마스킹, 감사로그 준수 |
| Code Quality | 10% | DRY, SRP, Rails 컨벤션 |

### 6.2 Match Rate Calculation

```
Match Rate = sum(dimension_score * weight) / 100

Where each dimension_score:
  100: 완전 일치
  80-99: 경미한 차이 (Minor gaps)
  50-79: 상당한 차이 (Moderate gaps)
  0-49: 미구현 또는 심각한 불일치 (Critical gaps)
```

### 6.3 Issue Severity Classification

| Severity | Definition | Action |
|----------|-----------|--------|
| Critical | 기능 미작동, 보안 취약, 데이터 손실 가능 | 즉시 수정, Act 반복 필수 |
| Major | 기능 불완전, 성능 미달, 사용성 저해 | Act 반복 시 수정 |
| Minor | 컨벤션 위반, 코드 중복, 문서 누락 | 개선 권고 |
| Info | 최적화 제안, 리팩토링 기회 | 참고 사항 |

---

## 7. Feature-Specific QA Checklists

### F06: Assignment (가장 중요한 Feature)

- [ ] 필터링: 자격 미달 봉사자 제외됨
- [ ] 필터링: blackout 기간 봉사자 제외됨
- [ ] 필터링: 동시간 중복 배정 방지됨
- [ ] 스코어링: 최근 수행 횟수 반영됨
- [ ] 스코어링: 선호도 보너스 반영됨
- [ ] 스코어링: 패널티 반영됨
- [ ] 결과: Top K 후보 정확히 반환됨
- [ ] 결과: 후보 부족 시 경고 발생
- [ ] 수동 배정: 드래그/드롭 또는 선택 정상 동작
- [ ] 성능: 2000명 기준 < 2초
- [ ] 회귀: 고정 시나리오 테스트 통과
- [ ] RBAC: operator 이상만 배정 가능
- [ ] 감사: 배정 변경 로그 기록됨

### F07: Response Flow (상태 전이 검증)

- [ ] pending -> accepted: 정상
- [ ] pending -> declined: 정상
- [ ] declined -> substitute_requested: 대타 요청 생성
- [ ] substitute_requested -> replaced: 원 배정 상태 변경
- [ ] 잘못된 전이 시도: 에러 반환
- [ ] 토큰 만료: 401 반환
- [ ] 토큰 재사용: 400 반환
- [ ] 동시 수락 방지: 레이스 컨디션 처리

---

## 8. Continuous QA Activities

### 8.1 Per-Commit Checks (CI)

```yaml
# .github/workflows/ci.yml
- RSpec (전체)
- RuboCop (lint)
- Brakeman (보안 스캔)
- SimpleCov (커버리지 >= 80%)
```

### 8.2 Per-Feature PDCA Check

```
gap-detector Agent 실행:
  1. Design 문서 로드
  2. 구현 코드 스캔
  3. 차이점 분석
  4. Match Rate 산출
  5. Issue 목록 생성
  6. Analysis 문서 작성
```

### 8.3 Pre-Release Check

```
E2E 시나리오 전체 실행
성능 벤치마크 실행
보안 스캔 (Brakeman) 실행
의존성 취약점 (bundler-audit) 점검
```

---

## 9. QA Agent Workflow (PDCA Check Phase)

```
                  ┌─────────────┐
                  │  Do 완료     │
                  └──────┬──────┘
                         v
              ┌──────────────────┐
              │ qa-strategist    │
              │ 테스트 전략 검토   │
              └────────┬─────────┘
                       v
          ┌────────────────────────┐
          │     gap-detector       │
          │ Design vs Code 분석    │
          └────────┬───────────────┘
                   v
          ┌────────────────────────┐
          │   code-analyzer        │
          │ 코드 품질/컨벤션 분석   │
          └────────┬───────────────┘
                   v
          ┌────────────────────────┐
          │  security-architect    │
          │ 보안/권한 검증         │
          └────────┬───────────────┘
                   v
              ┌──────────────────┐
              │ Match Rate 산출   │
              │ Analysis 문서     │
              └────────┬─────────┘
                       v
            ┌──────────────────────┐
            │ >= 90%? ──> Report   │
            │ < 90%?  ──> Act     │
            └──────────────────────┘
```

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | 2026-02-16 | Initial QA strategy (reinforced) | CTO Lead |
