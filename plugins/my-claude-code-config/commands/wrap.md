---
name: wrap
description: 대화에서 발견한 패턴을 시스템에 반영
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - AskUserQuestion
---

# Wrap Command

현재 대화에서 발견된 유용한 패턴, 워크플로우, 지식을 추출하여 `.claude/` 시스템에 반영합니다.

## Prerequisites

- **필수 스킬**: `claude-config-patterns` - 파일 구조, 템플릿, 식별 기준 참조

## Execution Flow

### Phase 1: 대화 분석

현재 대화 전체를 분석하여 Agent, Skill, Command, CLAUDE.md 후보를 식별합니다.

> **참조**: `claude-config-patterns` 스킬의 "식별 기준" 섹션

### Phase 2: 사용자 확인

AskUserQuestion 도구로 추출 항목 제시:

```
AskUserQuestion:
  questions:
    - question: "대화에서 다음 항목들을 추출할 수 있습니다. 반영할 항목을 선택하세요."
      header: "추출 항목"
      multiSelect: true
      options:
        - label: "[Agent] {name}"
          description: "{설명}"
        - label: "[Skill] {name}"
          description: "{설명}"
        - label: "[Command] {name}"
          description: "{설명}"
        - label: "[CLAUDE.md] {내용 요약}"
          description: "{상세 설명}"
```

### Phase 3: 파일 반영

사용자가 선택한 항목만 반영:

> **참조**: `claude-config-patterns` 스킬의 템플릿, 체크리스트, 디렉토리 구조

## 결과 보고

반영 완료 후 다음 정보 출력:
- 생성/수정된 파일 목록
- 각 파일의 변경 내용 요약

## Example

```
사용자: /wrap

Claude: 대화를 분석합니다...

[AskUserQuestion 호출]
Options:
□ [Agent] setup-project - 프로젝트 초기화 자동화
□ [Skill] api-error-handling - API 에러 처리 패턴
□ [CLAUDE.md] 새로운 환경변수 추가

사용자: setup-project, CLAUDE.md 선택

Claude:
완료! 다음 파일이 업데이트되었습니다:
- .claude/agents/setup-project.md (신규 생성)
- CLAUDE.md (환경변수 섹션 업데이트)
```

## 주의사항

- 추출할 내용이 없으면 "이 대화에서 추출할 패턴을 찾지 못했습니다." 메시지 출력
- 기존 파일과 이름이 충돌하면 사용자에게 덮어쓰기 여부 확인
- 파일 생성 시 반드시 `claude-config-patterns` 스킬 참조
