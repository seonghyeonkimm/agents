# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

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
