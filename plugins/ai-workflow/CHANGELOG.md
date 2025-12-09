# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.3.0] - 2025-12-09

### Added
- `/ai-workflow:clear` 명령어 추가
  - init.sh에서 실행한 프로세스 종료
  - 임시 파일 정리

### Changed
- `create-init-sh` 스킬을 `create-setup-sh`로 이름 변경
  - init.sh와 clear.sh 둘 다 생성하도록 확장

## [2.2.1] - 2025-12-09

### Changed
- `create-init-sh` 스킬에서 hook 관련 내용 제거
  - `/ai-workflow:init` 명령어로 실행되도록 문서 업데이트

## [2.2.0] - 2025-12-09

### Changed
- SessionStart hook을 `/ai-workflow:init` 명령어로 전환
  - 자동 실행 대신 명시적 명령어로 초기화
  - hooks 폴더 및 hooks.json 제거

### Added
- `/ai-workflow:init` 명령어 추가
  - `.ai-workflow/init.sh` 실행
  - Linear 작업 현황 조회 및 보고

## [2.1.4] - 2025-12-09

### Fixed
- hooks 등록 오류 수정
  - marketplace.json에서 `hooks` 필드 제거 (Claude Code가 `hooks/hooks.json`을 자동 발견)
  - hooks.json에서 `matcher` 필드 제거 (모든 SessionStart 이벤트에서 실행)

## [2.1.3] - 2025-12-09

### Fixed
- hooks가 모든 SessionStart 이벤트에서 실행되도록 수정
  - matcher를 `"startup"`에서 `"startup|resume|clear|compact"`로 변경
  - resume, clear, compact 시에도 init.sh가 실행됨

## [2.1.2] - 2025-12-09

### Changed
- hooks.json 설정 개선
  - `matcher: "startup"` 추가 (신규 세션 시작 시에만 실행)
  - `$CLAUDE_PROJECT_DIR` 환경변수 사용으로 경로 안정성 향상
  - `timeout: 30` 추가로 무한 대기 방지

## [2.1.1] - 2025-12-09

### Fixed
- hooks 스키마 오류 수정 (marketplace.json에서 hooks.json 파일로 분리)

## [2.1.0] - 2025-12-09

### Changed
- `add-issue` 명령어를 문서 기반 이슈 생성으로 개선
  - 로컬 spec/plan 문서 경로를 입력받아 Linear 이슈 생성
  - 3가지 필수 검증 기준 추가 (작업 상세도, 기술 구현 내용, 평가 기준)
  - 검증 통과 전에는 이슈 생성 불가

### Removed
- `create-spec-doc` 스킬 삭제

## [2.0.0] - 2025-12-08

### Changed
- Linear 기반 workflow로 전환
- 기존 feature-list.json 기반에서 Linear API 기반으로 변경
