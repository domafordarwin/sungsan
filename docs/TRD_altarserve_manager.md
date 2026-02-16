# TRD — 성단(전례 봉사) 신자 관리 자동화 웹앱 (AltarServe Manager, 가칭)

## 1. 기술 목표
- 모바일 웹 중심 UX(봉사자 수락/거절 최소 동선)
- 배정 자동화 알고리즘(규칙 기반) + 운영자 수동 조정 가능
- 권한/감사 로그 필수(누가 무엇을 언제 바꿨는지)
- 개인정보 보호(마스킹/접근제어/보관 정책)

## 2. 기술 스택(권장, 환경 가정)
- **Backend:** Ruby 2.7.8 + Rails 5.2.4
- **DB:** PostgreSQL
- **Cache/Jobs:** Redis + Sidekiq(알림/리마인더/반복 생성)
- **Frontend:** Rails 서버 렌더링 + 최소 JS(필요 시 Stimulus)
- **Auth:** Devise(권장) + RBAC(Role-based access control)
- **Deployment:** Railway(또는 Render/Fly) + Postgres addon
- **Observability:** Sentry(에러), 로그 드레인, Health endpoint

## 3. 아키텍처 개요
- Rails 모놀리식
- 도메인 모듈
  - **Scheduling:** 일정/반복 생성
  - **Assignment:** 배정/대타/추천 알고리즘
  - **Attendance:** 출결
  - **Notifications:** 알림/리마인더
  - **Admin:** 설정/권한/감사로그
- 외부 연동(선택): Email → SMS/Kakao(후순위)

## 4. 데이터 모델(초안)

### 핵심 테이블
- `parishes` (확장 대비 멀티 본당)
- `users` (로그인 계정)
- `members` (봉사자 프로필: 신자 정보)
- `roles` (역할 정의)
- `event_types` (미사 유형 템플릿)
- `events` (개별 미사/행사 인스턴스)
- `event_role_requirements` (event_type별 role 필요 인원/조건)
- `assignments` (event_id, role_id, member_id, status)
- `attendance_records` (assignment_id 또는 event_id+member_id, 상태/사유)
- `availability_rules` (member별 가능 요일/시간/미사종류)
- `blackout_periods` (member 휴가/시험 기간)
- `qualifications` (교육/자격 정의)
- `member_qualifications` (이수/만료)
- `notifications` (발송 이력, 채널, 상태)
- `audit_logs` (변경 이력)

### 상태값 예시
- `assignments.status`: `pending | accepted | declined | replaced | canceled`
- `attendance_records.status`: `present | late | absent | excused | replaced`

## 5. API/기능 설계(요약)

### 일정/배정
- `POST /events/generate` : 반복 일정 생성(기간/주차/미사 유형)
- `POST /events/:id/assignments/auto` : 자동 추천/배정(초기엔 추천 리스트 반환 후 확정)
- `PATCH /assignments/:id` : 수동 변경(담당자)
- `POST /assignments/:id/response` : 봉사자 수락/거절(토큰 기반 링크 가능)

### 대타(대체) 플로우
- `POST /assignments/:id/substitute_requests`
  - 후보 추천(조건 충족 + 최근 수행 적은 순)
  - 일괄 요청 발송
- `POST /substitute_requests/:id/accept` : 대타 수락 → 원 배정 `replaced` 처리

### 출결
- `POST /events/:id/attendance/bulk` : 담당자 일괄 입력
- `GET /members/:id/history` : 봉사 이력/출결 조회

## 6. 자동 배정 알고리즘(규칙 기반, MVP)
입력: `event`, `role requirements`, `candidate members`

1) **필터링**
- 활성 사용자
- 해당 역할 가능
- 자격(교육/연령/세례·견진 등) 충족
- blackout 기간 제외
- 동시간 중복 배정 제외

2) **스코어링(낮을수록 우선)**
- 최근 N주 수행 횟수(역할별) × w1
- 최근 전체 봉사 횟수 × w2
- 거절/무단 결석 패널티 × w3
- 선호(가능 요일/미사) 보너스 × w4

3) **출력**
- 후보 랭킹(Top K) 제공 → 운영자가 확정 또는 자동 확정

## 7. 보안/권한
- RBAC: `admin`(본당 전체), `operator`(미사 담당), `member`(본인)
- 개인정보 마스킹:
  - 연락처/생년 정보는 권한별 부분 마스킹
- 감사로그:
  - 배정/출결/자격 변경은 모두 기록(누가/언제/무엇을)
- 링크 기반 응답(사용성 개선):
  - `assignment_response_token`(단기 만료)로 수락/거절 허용
- 멀티 본당 대비:
  - 모든 쿼리에 `parish_id` 스코프 강제

## 8. 백그라운드 작업(Background Jobs)
- 주간/월간 일정 자동 생성(옵션)
- 미사 전 리마인더(예: 48h/24h/3h 전)
- 거절 발생 시 후보 추천/요청 생성(옵션)
- 통계 집계(월별/역할별)

## 9. 운영/배포
- Railway 구성 예:
  - Web 서비스 + Postgres + (선택) Redis
- 필수 환경변수:
  - `DATABASE_URL`, `SECRET_KEY_BASE`, `RAILS_ENV`
  - (선택) `REDIS_URL`, `SMTP_*`, 알림 연동 키
- 마이그레이션/시드:
  - 역할 템플릿, 미사 유형 템플릿 기본 제공
- 백업:
  - DB 자동 백업 정책(주기/보관 기간)

## 10. 테스트/품질
- RSpec 권장(모델/서비스/권한)
- 배정 알고리즘 회귀 테스트(샘플 데이터 고정)
- 권한 테스트(역할별 접근 제한)
- 성능:
  - 본당 규모(예: 200~2000명)에서 조회/배정 성능 점검
