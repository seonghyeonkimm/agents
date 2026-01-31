# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0] - 2026-01-31

### Added
- `wrap` command: 대화에서 발견한 패턴을 시스템에 반영
- `claude-config-patterns` skill: Agent, Skill, Command 파일 작성 패턴 및 템플릿
- `code-dojo` skill: Interactive code learning through skeleton-based exercises
- `settings.json` config: hooks (Stop, Notification, UserPromptSubmit), statusLine, enabledPlugins
- `settings.local.json` config: MCP permission overrides
- `skill-activation-forced-eval.sh` hook: UserPromptSubmit hook for mandatory skill evaluation
- `statusline.sh`: Custom status line with git branch, time, model info
- `sync.sh`: Bidirectional sync script (export/import/diff)
