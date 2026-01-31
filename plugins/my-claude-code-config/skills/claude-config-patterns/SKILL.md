---
name: claude-config-patterns
description: Agent, Skill, Command 파일 작성 패턴 및 템플릿
globs:
  - ".claude/agents/**"
  - ".claude/skills/**"
  - ".claude/commands/**"
---

# Claude Config Patterns

`.claude/` 디렉토리 내 파일 작성 시 따라야 할 패턴과 템플릿입니다.

---

## 식별 기준

대화에서 추출할 내용의 타입을 결정하는 기준입니다.

| 타입 | 식별 기준 | 예시 |
|------|-----------|------|
| **Agent** | 여러 단계로 구성된 자동화 작업, 특정 도구 조합이 필요한 워크플로우 | "프로젝트 초기화", "배포 파이프라인" |
| **Skill** | 특정 파일 패턴에 적용되는 규칙, 반복되는 코딩 컨벤션 | "API 에러 처리 패턴", "테스트 작성 규칙" |
| **Command** | 사용자가 자주 요청하는 작업, 인자를 받아 실행되는 반복 작업 | "/deploy", "/test-coverage" |
| **CLAUDE.md** | 프로젝트 제약사항, API 사용 규칙, 디렉토리 구조 | "환경변수 추가", "라이브러리 사용 규칙" |

### Agent vs Skill vs Command 구분

```
Q: 도구(Read, Write, Bash 등)를 사용해야 하는가?
├─ Yes → Q: 사용자가 직접 호출하는가?
│         ├─ Yes → Command
│         └─ No → Agent
└─ No → Skill (참조 문서)
```

---

## 디렉토리 구조

```
.claude/
├── agents/           # 자동화 워크플로우 실행자
│   └── {name}.md
├── skills/           # 재사용 패턴 및 규칙 (참조용)
│   └── {name}/
│       └── SKILL.md
└── commands/         # 사용자 명령어 (진입점)
    └── {name}.md 또는 {category}/{name}.md
```

---

## Agent 템플릿

**위치:** `.claude/agents/{name}.md`

**용도:** 특정 도구를 사용해 자동화 작업을 수행하는 실행자

```yaml
---
name: {agent-name}
description: {한 줄 역할 설명}
tools: {도구 목록 (공백 구분)}
---

# {Agent Name}

{상세 설명}

## Prerequisites
- 필요한 스킬: `{skill-name}`
- 필요한 환경: {환경 요구사항}

## Workflow

### Phase 1: {단계명}
{단계 설명}

### Phase 2: {단계명}
{단계 설명}

## Error Handling
- {에러 상황}: {대응 방법}

## Example
{사용 예시}
```

### Agent Tools 가이드

| 도구 | 용도 | 예시 |
|------|------|------|
| `Read` | 파일 읽기 | 스크립트, 설정 파일 읽기 |
| `Write` | 파일 생성 | JSON, 설정 파일 생성 |
| `Edit` | 파일 수정 | 기존 파일 일부 수정 |
| `Bash` | 명령 실행 | npm, npx, 시스템 명령 |
| `Glob` | 파일 검색 | 패턴으로 파일 찾기 |
| `Task` | 서브에이전트 위임 | 다른 에이전트 호출 |
| `WebFetch` | 웹 요청 | API 호출, 문서 조회 |
| `AskUserQuestion` | 사용자 입력 | 확인, 선택 요청 |

### Agent 네이밍 규칙

- kebab-case 사용: `script-writer`, `audio-generator`
- 역할을 명확히 표현: `{동작}-{대상}` 패턴
- 짧고 명확하게: 2-3 단어

---

## Skill 템플릿

**위치:** `.claude/skills/{name}/SKILL.md`

**용도:** 특정 파일 패턴에 자동 적용되는 참조 문서 (규칙, 패턴, 예제)

```yaml
---
name: {skill-name}
description: {한 줄 설명}
globs:
  - "{glob-pattern-1}"
  - "{glob-pattern-2}"
---

# {Skill Name}

{개요 설명}

## 핵심 규칙

### 규칙 1: {규칙명}
{규칙 설명}

```{lang}
// ✅ 올바른 예시
{good example}

// ❌ 잘못된 예시
{bad example}
```

## 템플릿/스키마

```{lang}
{재사용 가능한 코드/구조}
```

## 흔한 실수와 해결책

| 문제 | 원인 | 해결 |
|------|------|------|
| {문제} | {원인} | {해결책} |
```

### Globs 패턴 가이드

| 패턴 | 매칭 대상 |
|------|-----------|
| `**/*.ts` | 모든 TypeScript 파일 |
| `src/**` | src 디렉토리 내 모든 파일 |
| `.claude/agents/**` | 에이전트 파일들 |
| `**/test*/**` | test가 포함된 경로 |

### Skill 네이밍 규칙

- kebab-case 사용: `remotion-patterns`, `api-error-handling`
- `{도메인}-{타입}` 패턴 권장: `video-script-rules`
- 디렉토리명 = name 필드값

---

## Command 템플릿

**위치:** `.claude/commands/{name}.md` 또는 `.claude/commands/{category}/{name}.md`

**용도:** 사용자가 `/name` 또는 `/{category}/{name}`으로 호출하는 진입점

```yaml
---
name: {command-name 또는 category/command-name}
description: {사용자에게 보여지는 설명}
arguments:
  - name: {arg-name}
    description: {인자 설명}
    required: true|false
    default: {기본값 (optional)}
allowed-tools:
  - {사용할 도구 목록}
---

# {Command Name}

{명령어 개요}

## Input
- `$ARGUMENTS.{arg-name}`: {설명}

## Execution Flow

### 1. {단계명}
{단계 설명}

### 2. {단계명}
{단계 설명}

## Example
```
/command-name --arg1 "value1" --arg2 value2
```
```

### Command 네이밍 규칙

- 단일 단어 또는 카테고리/이름: `wrap`, `video/generate`
- 동사로 시작: `generate`, `render`, `validate`
- 사용자 관점에서 직관적으로

---

## CLAUDE.md 업데이트 가이드

**위치:** 프로젝트 루트 `CLAUDE.md`

**용도:** 프로젝트 컨텍스트, 제약사항, 규칙

### 추가할 내용 유형

1. **프로젝트 구조** - 새 디렉토리, 파일 구조
2. **환경 변수** - 새 API 키, 설정값
3. **핵심 패턴** - 반드시 따라야 할 규칙
4. **명령어** - 새 CLI 명령, 스크립트

### 추가 위치 가이드

| 내용 유형 | 추가 위치 |
|-----------|-----------|
| 디렉토리 구조 | `## 저장소 구조` 섹션 |
| CLI 명령어 | `## 주요 명령어` 섹션 |
| API 사용 규칙 | `## 핵심 패턴` 섹션 |
| 환경 변수 | `## 환경 변수` 섹션 |

### 작성 스타일

- 간결하게 (한 항목당 1-2줄)
- 코드 예시 포함
- ✅/❌ 로 올바른/잘못된 예시 구분

---

## 체크리스트

### Agent 생성 시
- [ ] name이 kebab-case인가?
- [ ] tools에 필요한 도구만 포함했는가?
- [ ] Workflow가 단계별로 명확한가?
- [ ] Error Handling이 있는가?

### Skill 생성 시
- [ ] globs가 정확한 패턴인가?
- [ ] 규칙에 ✅/❌ 예시가 있는가?
- [ ] 흔한 실수 섹션이 있는가?

### Command 생성 시
- [ ] arguments가 명확히 정의되었는가?
- [ ] allowed-tools가 최소한인가?
- [ ] Example이 있는가?
