# CLAUDE.md

이 파일은 Claude Code (claude.ai/code)가 이 저장소에서 작업할 때 참고하는 가이드입니다.

## 프로젝트 개요

Claude Code 기능을 확장하는 커스텀 플러그인을 포함하는 플러그인 마켓플레이스 저장소입니다. 플러그인은 다음을 포함할 수 있습니다:
- **Agents**: 특화된 작업 처리기 (name, description, model을 정의하는 frontmatter가 있는 마크다운 파일)
- **Commands**: 프롬프트로 확장되는 슬래시 명령어 (`commands/` 내 마크다운 파일)
- **Skills**: 재사용 가능한 지식/기술 (`SKILL.md`와 선택적 `assets/`, `references/` 하위 디렉토리를 포함하는 디렉토리)

## 저장소 구조

```
.claude-plugin/
  marketplace.json    # 메타데이터와 플러그인 정의가 포함된 플러그인 레지스트리
plugins/
  <plugin-name>/
    agents/           # 에이전트 정의 파일 (.md)
    commands/         # 명령어 정의 파일 (.md)
    skills/           # SKILL.md를 포함하는 스킬 디렉토리
```

## 플러그인 정의 형식

플러그인은 `.claude-plugin/marketplace.json`에 등록됩니다. 각 플러그인 항목에는 다음이 포함됩니다:
- 소스 경로, 설명, 버전 및 메타데이터
- agents, commands, skills에 대한 상대 경로 배열

## 새 플러그인 생성하기

1. `plugins/<plugin-name>/` 아래에 새 디렉토리 생성
2. 필요에 따라 하위 디렉토리 추가: `agents/`, `commands/`, `skills/`
3. `.claude-plugin/marketplace.json`에 모든 경로와 함께 플러그인 등록

### Agent 파일
```markdown
---
name: agent-name
description: 이 에이전트를 사용해야 할 때
model: haiku|sonnet|opus
---

에이전트 지시사항...
```

### Command 파일
명령어가 호출될 때 확장되는 프롬프트 템플릿을 포함하는 마크다운 파일.

### Skill 디렉토리
frontmatter(name, description)가 포함된 `SKILL.md`가 필수. 보조 자료를 위한 `assets/`와 `references/` 하위 디렉토리 포함 가능.
