# Changelog

모든 주목할 만한 변경 사항이 이 파일에 기록됩니다.

이 프로젝트는 [Semantic Versioning](https://semver.org/ko/)을 따릅니다.

## [Unreleased]

## [0.3.0] - 2026-02-02

### Added

- **Phase 3 구현**: Given/When/Then Test Cases 자동 생성
  - `techspec-template` skill: Section 5 상세 가이드 추가
    - FE 중심 테스트 구조 (UI Component → Interaction → State Change)
    - Happy Path vs Edge Cases 분리 전략
    - Given/When/Then 작성 가이드 (Given=UI상태, When=사용자액션, Then=UI변화)
    - UI State Transition 명시 규칙
    - 좋은/나쁜 예시 (FE UI 중심 vs 백엔드 Event Sourcing)
  - `test-designer` agent: test-cases.md 파일 자동 생성
    - AC 기반 Happy Path TC 생성 (1 AC = 1 TC)
    - Feature별 Edge Cases 자동 추가 (로딩/에러/빈상태/네트워크)
    - NFR 기반 Non-Functional TC 생성 (성능/접근성/보안)
    - Entity 및 UI Component 자동 추출

## [0.2.0] - 2026-02-02

### Added

- **Phase 2 구현**: Acceptance Criteria & Non-Functional Requirements 자동 작성
  - `techspec-template` skill: AC/NFR 작성 규칙 및 템플릿 추가
    - AC 작성 규칙: 비기술적 언어, 사용자 관점, 독립적 테스트 가능
    - NFR 카테고리: 성능, 신뢰성, 보안, 확장성, 유지보수성
  - `acceptance-criteria` agent: AC + NFR 파일 자동 생성
    - Solution 기반 기능 단위 AC 작성
    - PRD/Solution 기반 NFR 작성

## [0.1.0] - 2026-02-02

### Added

- **Phase 1 구현**: Linear Project 기반 FE TechSpec 자동 작성
  - `techspec-template` skill: FE TechSpec 전체 구조 및 Solution 작성 가이드
  - `spec-writer` agent: Context + Solution 파일 자동 생성
  - `.claude/docs/{project-name}/` 디렉토리 구조로 프로젝트별 문서 관리
