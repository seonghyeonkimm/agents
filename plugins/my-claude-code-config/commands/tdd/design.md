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

### Phase 2: 데이터 모델(Interface) & Usecase 추출

Linear TechSpec 문서의 **Functional Requirements (Given/When/Then)** 섹션을 분석하여:

1. **데이터 모델 정의 (Interface 레이어)**:
   - 테스트 케이스의 Given/Then에서 참조하는 데이터를 식별
   - API 응답 모델을 기반으로 interface를 정의 → 컴포넌트는 이 interface에만 의존
   - 대부분 API 타입을 참조하면 충분. 별도 클라이언트 Entity는 정말 필요한 경우에만 추가
   - 별도 Entity가 필요한 경우: 여러 API 응답 조합, 클라이언트 고유 상태, API와 다른 구조
   - enum/상수값은 별도 정의 가능

2. **Domain Usecase 정의**:
   - 테스트 케이스의 When에서 사용자 행동/이벤트를 Usecase로 변환
   - 각 Usecase의 input/output 정의
   - **컴포넌트 렌더링 분기(단순 if/else)는 Usecase에서 제외** — 컴포넌트 내부 책임
   - Usecase가 참조하는 데이터 매핑

**출력 형식:**

```markdown
## Domain Model

### 데이터 모델

| 데이터 | 출처 | 주요 필드 | interface 전략 |
|--------|------|----------|---------------|
| {데이터명} | API response | `{field1}`, `{field2}` | API 타입 참조 |
| {데이터명} | 클라이언트 조합 | `{field1}`, `{field2}` | 별도 정의 (사유: 여러 API 조합) |

### Usecases

#### {UsecaseName}
- **Actor**: {who triggers}
- **Input**: {input params}
- **Output**: {output/side effects}
- **데이터 참조**: {related data}
- **Test Cases**: #{test case numbers}
```

### Phase 2.5: Business Rules 추출

테스트 케이스에서 반복 등장하는 비즈니스 규칙을 자연어로 식별한다.
⚠️ 함수명/시그니처/의존성 구조는 설계하지 않는다. 구현 시 TDD Refactor 단계에서 `entity-object-pattern` 스킬을 참조하여 결정.

**추출 기준:**

- 2곳 이상에서 참조되는 규칙만 추출
- 컴포넌트의 단순 렌더링 분기(예: "데이터가 0건이면 empty view 노출")는 비즈니스 규칙이 아님 — 해당 컴포넌트의 렌더링 책임
- "상태 조건", "행동 제약"처럼 여러 컴포넌트/API/테스트에서 반복되는 로직만 대상

**추출 프로세스:**

1. **Given에서 상태 조건 식별**: "~인 상태", "~가 설정된" 등에서 도메인 제약 추출
2. **When에서 행동 제약 식별**: "시도하면 실패", "수정 불가" 등에서 행동 가능 조건 추출
3. **Then에서 결과 규칙 식별**: 파생 값, 조건부 UI 동작 등 추출
4. **참조 횟수 검증**: 추출한 규칙이 2곳 이상에서 사용되는지 확인. 1곳만이면 제외

**출력 형식:**

```markdown
### Business Rules

⚠️ 테스트 케이스에서 비즈니스 규칙을 자연어로 추출. 함수명/시그니처는 구현 시 결정.
⚠️ 2곳 이상에서 참조되는 규칙만 기록. 단일 컴포넌트 렌더링 분기는 제외.

| Rule ID | 참조 지점 | 규칙 유형 | 규칙 설명 | # |
|---------|----------|----------|----------|-----|
| BR-1 | {ComponentA, ComponentB} | 상태 조건 | {자연어 설명} | #1,#2 |
| BR-2 | {UI, API request} | 행동 제약 | {자연어 설명} | #3 |
```

### Phase 3: Client Component & State 설계

Linear TechSpec의 테스트 케이스 + Figma 디자인 (meta.yaml의 sources.figma가 있는 경우)을 기반으로:

1. **Figma 컨텍스트 로드** (URL이 있는 경우):
   ```
   ToolSearch(query: "select:mcp__plugin_figma_figma__get_design_context")
   → 컴포넌트 구조, 레이아웃, 상태 변화 추출
   ```

2. **Component Tree 설계**:
   - 페이지/화면 단위로 컴포넌트 계층 정의
   - 각 컴포넌트의 Props interface
   - 재사용 가능한 공통 컴포넌트 식별

3. **State 설계**:
   - Interface 데이터 → Client State 매핑
   - 서버 상태 vs 클라이언트 상태 구분
   - State management 방식 결정

**출력 형식:**

```markdown
## Client Architecture

### Component Tree

{PageName}/
├── {ContainerComponent}  → Usecase 연결
│   ├── {PresentationalComponent}
│   └── {PresentationalComponent}
└── ...

### Component Specs

#### {ComponentName}
- **Props**: { prop: type }
- **State**: { state: type }
- **Usecase**: {connected usecase}

### State Design

#### Server State (React Query / SWR)
- {query key}: {description}

#### Client State
- {state name}: {description}
```

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

### 4. Component & States
컴포넌트 계층 + State 설계

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
