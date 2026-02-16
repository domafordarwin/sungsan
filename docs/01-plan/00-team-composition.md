# AltarServe Manager - Agent Team Composition

> **Project**: AltarServe Manager (성단 매니저)
> **Level**: Enterprise (PDCA Strict Mode)
> **Date**: 2026-02-16
> **Status**: Approved

---

## 1. Project Level Justification

AltarServe Manager는 Enterprise 레벨로 분류합니다.

| 판단 기준 | 해당 여부 | 근거 |
|-----------|:---------:|------|
| 복잡한 도메인 로직 | O | 자동 배정 알고리즘, RBAC, 멀티테넌시 |
| 다수 테이블/관계 | O | 15개 이상 핵심 테이블, 복잡한 관계 |
| 보안 요구사항 | O | 개인정보 보호, 감사로그, 권한 제어 |
| 백그라운드 작업 | O | Sidekiq 기반 알림/리마인더/통계 집계 |
| 품질 기준 높음 | O | 성당 운영 시스템으로 안정성 필수 |

단, 기술 스택은 TRD에 명시된 **Ruby 2.7.8 + Rails 5.2.4 모놀리식** 아키텍처를 따릅니다.
Enterprise 레벨의 팀 구성과 품질 관리 프로세스를 적용하되, 마이크로서비스가 아닌
Rails 모놀리식 내부의 도메인 모듈 분리 패턴을 사용합니다.

---

## 2. Agent Team Structure (5 Teammates)

### 2.1 Team Overview

```
                    CTO Lead (cto-lead, Opus)
                    ┌───────────┐
                    │ 기술 방향  │
                    │ 품질 게이트 │
                    │ PDCA 조율  │
                    └─────┬─────┘
          ┌───────────┬───┴───┬───────────┬──────────┐
          v           v       v           v          v
   ┌──────────┐ ┌─────────┐ ┌─────────┐ ┌────────┐ ┌──────────┐
   │Architect │ │Developer│ │   QA    │ │Reviewer│ │Security  │
   │설계/아키텍처│ │구현 전담 │ │품질 검증 │ │코드 리뷰 │ │보안 감사  │
   └──────────┘ └─────────┘ └─────────┘ └────────┘ └──────────┘
```

### 2.2 Role Definitions

#### CTO Lead (cto-lead) - Orchestrator
- **Model**: Opus
- **Responsibility**: 전체 PDCA 사이클 조율, 기술 의사결정, 품질 게이트 관리
- **Actions**:
  - Plan/Act 단계에서 Leader 패턴으로 작업 분배
  - Design/Check 단계에서 Council 패턴으로 다각도 검증
  - Do 단계에서 Swarm 패턴으로 병렬 구현 지시
  - Match Rate >= 90% 달성 시 Report 단계로 전환 승인

#### Architect (enterprise-expert, frontend-architect)
- **PDCA Phase**: Design (주도), Check (참여)
- **Responsibility**:
  - Rails 모놀리식 내 도메인 모듈 설계
  - 데이터베이스 스키마 설계 및 마이그레이션 전략
  - 자동 배정 알고리즘 설계
  - API 인터페이스 설계
  - Stimulus 기반 프론트엔드 아키텍처

#### Developer (bkend-expert)
- **PDCA Phase**: Do (주도), Act (수정 구현)
- **Responsibility**:
  - Rails 모델/컨트롤러/서비스 구현
  - Sidekiq 백그라운드 잡 구현
  - Devise 인증/인가 구현
  - 데이터베이스 마이그레이션 작성
  - Stimulus 컨트롤러 구현

#### QA Strategist (qa-strategist, qa-monitor, gap-detector)
- **PDCA Phase**: Check (주도), Act (검증)
- **Responsibility**:
  - RSpec 테스트 전략 수립 및 실행
  - Design 문서 대비 구현 Gap 분석
  - 배정 알고리즘 회귀 테스트
  - 권한/보안 테스트
  - 성능 테스트 (200~2000명 규모)
  - Match Rate 산출 및 리포트

#### Reviewer (code-analyzer, design-validator)
- **PDCA Phase**: Check (참여), Act (참여)
- **Responsibility**:
  - 코드 품질 분석 (DRY, SRP 준수)
  - Design 문서와 구현의 일관성 검증
  - Rails 컨벤션 준수 확인
  - N+1 쿼리, 보안 취약점 코드 리뷰
  - 리팩토링 제안

#### Security Architect (security-architect)
- **PDCA Phase**: Design (참여), Check (참여)
- **Responsibility**:
  - RBAC 설계 검증
  - 개인정보 보호 정책 준수 확인
  - 감사로그 완전성 검증
  - 토큰 기반 인증 보안 리뷰
  - OWASP Top 10 대응 검증

---

## 3. Orchestration Patterns by PDCA Phase

| Phase | Pattern | Lead Agent | Support Agents | 산출물 |
|-------|---------|------------|----------------|--------|
| Plan | Leader | CTO Lead | Product Manager | Plan 문서 |
| Design | Council | Architect | Security, CTO Lead | Design 문서 |
| Do | Swarm | Developer | Architect (자문) | 구현 코드 |
| Check | Council | QA Strategist | Reviewer, Security | Analysis 문서 |
| Act | Leader | CTO Lead | Developer, QA | 수정 코드 + 재검증 |

### 3.1 Phase Transition Quality Gates

```
Plan ──[Plan 문서 승인]──> Design ──[Design 문서 승인]──> Do
                                                          │
Do ──[구현 완료 확인]──> Check ──[Match Rate 판정]──> Act/Report
                                                     │
                              Match Rate < 70%: Design 재검토
                              Match Rate 70-89%: Act 반복 (최대 5회)
                              Match Rate >= 90% AND Critical = 0: Report
```

---

## 4. QA Reinforcement Strategy (강화된 품질 관리)

사용자 요청에 따라 QA 에이전트를 특별히 강화합니다.

### 4.1 Multi-Layer QA Approach

```
Layer 1: Unit Testing (RSpec)
├── Model specs: 모든 모델 유효성/관계/스코프
├── Service specs: 비즈니스 로직 (특히 배정 알고리즘)
├── Controller specs: 라우팅/권한/응답
└── Job specs: Sidekiq 잡 동작

Layer 2: Integration Testing
├── Feature specs (Capybara): 주요 사용자 플로우
├── API specs: 엔드포인트 통합 테스트
└── Auth specs: 역할별 접근 제어

Layer 3: Gap Analysis (Check Phase)
├── Design vs Code 일치도 분석
├── PRD 요구사항 충족률 분석
└── 누락 기능/경로 식별

Layer 4: Security & Performance
├── RBAC 관통 테스트
├── 개인정보 마스킹 검증
├── 감사로그 완전성
└── 대규모 데이터 성능 (N+1 쿼리 등)
```

### 4.2 QA Checkpoints per Feature

| Checkpoint | Trigger | QA Action |
|------------|---------|-----------|
| Pre-Design | Design 문서 작성 전 | PRD 요구사항 추적 매트릭스 작성 |
| Post-Design | Design 문서 완료 후 | 테스트 전략 수립, 테스트 케이스 설계 |
| Mid-Do | 구현 50% 진행 | 중간 점검, 조기 Gap 발견 |
| Post-Do | 구현 완료 | 전체 Gap Analysis + 테스트 실행 |
| Post-Act | 수정 후 | 회귀 테스트 + 재분석 |

### 4.3 QA Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| Match Rate | >= 90% | Design vs Implementation Gap Analysis |
| Test Coverage | >= 80% | SimpleCov |
| Critical Issues | 0 | Gap Analysis Report |
| Security Issues | 0 | RBAC/Auth Test Suite |
| Performance | < 500ms response | Benchmark tests |

---

## 5. Communication Protocol

### 5.1 Agent Communication Flow

```
CTO Lead
  │
  ├── write(architect, "Design Phase 시작: {feature}")
  │     └── architect responds with design draft
  │
  ├── write(security, "보안 검토 요청: {design}")
  │     └── security responds with review
  │
  ├── broadcast("Design 승인. Do Phase 진행")
  │     └── all agents acknowledge
  │
  ├── write(developer, "구현 시작: {tasks}")
  │     └── developer implements
  │
  ├── write(qa, "Check Phase: Gap Analysis 실행")
  │     └── qa responds with analysis
  │
  └── write(reviewer, "코드 리뷰 요청")
        └── reviewer responds with findings
```

### 5.2 Escalation Rules

| Situation | Action |
|-----------|--------|
| Match Rate < 70% (2회 연속) | CTO Lead가 Design 재검토 소집 |
| Security Critical 발견 | Security Agent가 즉시 CTO Lead에 보고 |
| 기술적 블로커 | Developer가 Architect에 자문 요청 |
| QA/Reviewer 의견 충돌 | CTO Lead가 최종 판정 |

---

## Version History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.0 | 2026-02-16 | Initial team composition | CTO Lead |
