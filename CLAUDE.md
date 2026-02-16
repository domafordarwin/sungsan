# Project: AltarServe Manager (성산)

## Overview
제대봉사자(복사) 관리 시스템 - 가톨릭 성당의 제대봉사 스케줄 및 인원 관리

## Tech Stack
- **Backend**: Ruby 3.2+ + Rails 8.0
- **Database**: PostgreSQL 16+
- **Queue**: Solid Queue (DB-backed, Redis 불필요)
- **Cache**: Solid Cache (DB-backed)
- **WebSocket**: Solid Cable (DB-backed)
- **Auth**: Rails 8 빌트인 인증 generator + Pundit (RBAC)
- **Frontend**: Hotwire 2.0 (Turbo + Stimulus) + Propshaft + Import Maps
- **Testing**: RSpec + FactoryBot + SimpleCov
- **Lint**: RuboCop + rubocop-rails
- **Security**: Brakeman + bundler-audit
- **Deployment**: Railway + Postgres addon (Redis 불필요)

## Architecture
- Rails Monolith with Domain Modules
- Modules: Scheduling, Assignment, Attendance, Notifications, Admin
- Service Objects for business logic (app/services/)
- Pundit Policies for authorization (app/policies/)
- Solid Queue Jobs for background tasks (app/jobs/)
- Concerns for cross-cutting (Auditable, ParishScoped, Maskable)

## RBAC
- admin: 본당 전체 관리 (전례위원장)
- operator: 미사 담당 (운영자)
- member: 봉사자 본인 정보만

## Development Rules
- docs/ 폴더는 git에 커밋하지 않음 (로컬 전용)
- PDCA 사이클 기반 개발 진행
- bkit 에이전트 팀 활용 (Enterprise Level, 5 teammates)
- Feature 단위 PDCA: Plan -> Design -> Do -> Check -> Act -> Report
- Match Rate >= 90% 필수 (Check 통과 기준)
- 배정 알고리즘(AssignmentEngine)은 결정론적 회귀 테스트 필수
- 모든 CUD 작업에 감사로그 자동 기록
- 개인정보 마스킹 역할별 적용

## Branch Strategy
- main (production)
- develop (integration)
- feature/F{number}-{name} (feature branches)
- Commit format: [F{number}] {type}: {description}

## Repository
- Remote: https://github.com/domafordarwin/sungsan
- Branch: main
