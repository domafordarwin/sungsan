# F10: Statistics & Dashboard Plan

> **Feature**: 통계/대시보드 (참여율, 결석률, 인력부족 경고)
> **Dependencies**: F06, F08

## Requirements
| ID | Requirement |
|----|-------------|
| FR-15 | 통계 (참여율, 결석률, 월별 봉사 횟수) |
| FR-16 | 역할별 인력 부족 경고 |

## Scope
- DashboardController: 핵심 통계 카드 (이번 주 일정, 활성 봉사자, 미응답 배정)
- StatisticsController: 상세 통계 페이지
- 역할별 인력 부족 경고
- 월별 봉사 횟수 차트 데이터
