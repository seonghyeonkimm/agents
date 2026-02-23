---
name: tdd/design
description: TechSpec의 테스트 케이스 기반으로 데이터 모델(interface), Usecase, Client Component를 설계
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - ToolSearch
  - AskUserQuestion
  - Task
---

# TDD Design Command

`/tdd:spec`의 결과물을 기반으로 데이터 모델(API 기반 interface)과 비즈니스 규칙, 클라이언트 컴포넌트를 설계한다.

## Prerequisites

- **필수**: `/tdd:spec` 실행 완료 → `.claude/docs/{project-name}/meta.yaml` 존재
- **필수 스킬**: `fe-techspec` - 설계 패턴 참조
- **선택 스킬**: `entity-object-pattern` - 구현 시 Refactor 단계에서 참조
- **필수 MCP**: Linear plugin (문서 읽기/업데이트)
- **선택 MCP**: Figma plugin (컴포넌트 상세 분석 시)

## Execution Flow

### Phase 1: 메타데이터 로드 및 Linear 문서 조회

1. `.claude/docs/` 하위에서 프로젝트 메타데이터 파일을 찾는다:
   ```
   Glob(pattern: ".claude/docs/*/meta.yaml")
   ```
2. 여러 프로젝트가 있으면 AskUserQuestion으로 선택 요청
3. meta.yaml에서 `document.id`, `document.url`, `sources.figma` 등 메타데이터를 읽는다
4. Linear에서 TechSpec 문서 내용을 조회한다:
   ```
   ToolSearch(query: "select:mcp__plugin_linear_linear__get_document")
   → mcp__plugin_linear_linear__get_document(id: "{document.id}")
   ```
   - 문서 내용에서 **Functional Requirements (Given/When/Then)** 섹션 추출
   - `get_document` 도구가 없으면, 사용자에게 Linear URL을 안내하고 수동 확인 요청

### Phase 2-3: 설계 (tdd-designer agent 위임)

데이터 모델, Business Rules, Usecase, Component, Visual Contract 설계를 `tdd-designer` agent에 위임한다.

```
Task(
  subagent_type: "tdd-designer",
  prompt: """
  다음 TechSpec 문서를 분석하여 Domain Model + Client Architecture를 설계해주세요.

  ## TechSpec Functional Requirements
  {Linear 문서에서 추출한 Given/When/Then 섹션 전문}

  ## Figma URL (있는 경우)
  {meta.yaml의 sources.figma 값, 없으면 "없음"}

  ## 기존 Design 섹션 (업데이트 시)
  {기존 Design 내용, 최초 생성이면 "없음"}
  """
)
```

**agent 반환 결과**: 아래 섹션이 포함된 마크다운
- `## Design` (데이터 모델, Business Rules, Usecase, Component & Visual Contract, Usecase-Component Integration)
- `## Component & Code - Client`
- `## Verification`

### Phase 4: Linear 문서 업데이트

⚠️ **로컬 파일 수정 없음** - Linear 문서만 업데이트한다 (Single Source of Truth)

meta.yaml의 `document.id`로 TechSpec 문서에 Design 섹션을 추가한다:

```
ToolSearch(query: "select:mcp__plugin_linear_linear__update_document")
→ mcp__plugin_linear_linear__update_document(
    id: "{document.id}",
    content: "{기존 내용 + 아래 섹션 추가}"
  )
```

**추가되는 섹션:**

```markdown
## Design

### 1. 데이터 모델
API 기반 interface 정의. 별도 클라이언트 Entity는 사유 필요.

### 2. Business Rules
비즈니스 규칙 목록 (2곳 이상 참조되는 규칙만)

### 3. Usecase
Input → Output 테이블

### 4. Component & Visual Contract
컴포넌트 계층 설계. Container(Usecase 연결)와 Presentational(순수 UI) 분리.
- Container: Usecase, 데이터 흐름, State
- Presentational: Props, Callbacks, Visual Contract

### 5. Usecase-Component Integration
연결 지점 테이블

## Component & Code - Client
Test cases 기반으로 module, usecase, 컴포넌트 구조 추출

## Verification

⚠️ Integration Test 최우선.

### Integration Tests (필수)

⚠️ UI 렌더링 자체("~가 렌더링된다")보다 사용자 행동(클릭, 입력)과 그 결과(핸들러 호출, 상태 변경)를 검증.

| # | 테스트 명 | 검증 내용 |
|---|----------|----------|
| 1 | {테스트명} | {검증 내용} |

### Unit Tests (필요 시)

복잡한 파생 상태 로직만 대상.

### E2E Tests (필요 시)

전체 사용자 플로우 검증.
```

### Phase 5: 결과 보고

```
Design 완료!

Domain Model:
- 데이터 모델: {interface list}
- Business Rules: {N}개 (2곳 이상 참조)
- Usecases: {usecase list}

Client Architecture:
- Pages: {page list}
- Components: {N}개
- Shared: {shared component list}

Linear Document: {document URL} (Design 섹션 업데이트됨)
* 로컬 파일 수정 없음 - Linear가 Single Source of Truth

다음 단계:
1. Linear에서 설계를 리뷰하세요
2. /tdd:issues 로 Linear 이슈를 생성하세요
```

### Phase 6: (Human) Review

사용자가 Linear에서 도메인 모델과 컴포넌트 설계를 리뷰한다.

## Error Handling

| 상황 | 대응 |
|------|------|
| meta.yaml이 없음 | `/tdd:spec`을 먼저 실행하라고 안내 |
| Linear 문서 조회 실패 | 사용자에게 Linear URL 안내, 수동 확인 요청 |
| Linear 문서에 테스트 케이스가 없음 | 최소한의 데이터 모델/Usecase를 제안하고 확인 요청 |
| Figma URL이 없음 | 테스트 케이스만으로 컴포넌트 설계 진행 |
| Linear 문서 업데이트 실패 | 에러 메시지 출력, 재시도 안내 |

## Example

```
사용자: /tdd:design

Claude: .claude/docs/에서 메타데이터 파일을 찾고 있습니다...
  → .claude/docs/my-feature/meta.yaml 발견

Claude: Linear에서 TechSpec 문서를 조회합니다...
  → document.id: abc123

Claude: 테스트 케이스를 분석하여 데이터 모델과 비즈니스 규칙을 추출합니다...

Claude: Design 완료!
  Domain Model:
  - 데이터 모델: CartData (API 참조), ProductData (API 참조)
  - Business Rules: 3개
  - Usecases: AddToCart, RemoveFromCart, UpdateQuantity

  Client Architecture:
  - Pages: CartPage
  - Components: 8개
  - Shared: Button, QuantitySelector

  Linear Document: https://linear.app/daangn/document/fe-techspec-xxx (Design 섹션 추가됨)
```
