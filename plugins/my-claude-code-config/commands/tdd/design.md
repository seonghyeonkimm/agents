---
name: tdd/design
description: TechSpec의 테스트 케이스 기반으로 Domain Entity, Usecase, Client Component를 설계
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - ToolSearch
  - AskUserQuestion
---

# TDD Design Command

`/tdd:spec`의 결과물을 기반으로 도메인 모델과 클라이언트 컴포넌트를 설계한다.

## Prerequisites

- **필수**: `/tdd:spec` 실행 완료 → `.claude/docs/{project-name}/meta.yaml` 존재
- **필수 스킬**: `fe-techspec` - 설계 패턴 참조
- **필수 스킬**: `domain-invariant-pattern` - 불변식 헬퍼 함수 설계 참조
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

### Phase 2: Domain Entity & Usecase 추출

Linear TechSpec 문서의 **Functional Requirements (Given/When/Then)** 섹션을 분석하여:

1. **Domain Entity 정의**:
   - 테스트 케이스의 Given/Then에서 상태를 가진 개체 식별
   - Entity의 속성(properties)과 불변식(invariants) 정의
   - Entity 간 관계(relationships) 도출

2. **Domain Usecase 정의**:
   - 테스트 케이스의 When에서 사용자 행동/이벤트를 Usecase로 변환
   - 각 Usecase의 input/output 정의
   - Usecase가 참조하는 Entity 매핑

**출력 형식:**

```markdown
## Domain Model

### Entities

#### {EntityName}

| 속성 | 타입 | 설명 |
|------|------|------|
| `{property}` | `{type}` | {설명} |

### Usecases

#### {UsecaseName}
- **Actor**: {who triggers}
- **Input**: {input params}
- **Output**: {output/side effects}
- **Entity**: {related entities}
- **Test Cases**: #{test case numbers}
```

### Phase 2.5: Invariant Helper 함수 설계

`domain-invariant-pattern` 스킬을 참조하여 테스트 케이스에서 불변식을 추출한다.

**추출 프로세스:**

1. **Given에서 `is*` 함수 추출**: "~인 상태", "~가 설정된" 등의 조건에서 상태 체크 함수 도출
2. **When에서 `can*` 함수 추출**: "시도하면 실패", "수정 불가" 등에서 가능 조건 도출
3. **Then에서 `get*`, `should*` 함수 추출**: 파생 값, 조건부 동작 도출
4. **의존성 순서 정의**: Layer 1 (is*) → Layer 2 (can*, get*) → Layer 3 (should*)

**출력 형식:**

```markdown
### Invariant Helpers

#### Layer 1: Base Conditions (is*)

| 함수명 | 파라미터 | 반환 | 설명 | TC# |
|--------|----------|------|------|-----|
| `is{Condition}` | `entity: Entity` | `boolean` | {조건 설명} | #1,#2 |

#### Layer 2: Derived (can*, get*)

| 함수명 | 파라미터 | 반환 | 의존 | 설명 | TC# |
|--------|----------|------|------|------|-----|
| `can{Action}` | `entity: Entity` | `boolean` | `is*` | {가능 조건} | #1 |
| `get{Value}` | `entity: Entity` | `Type` | `is*` | {파생 값} | #3 |

#### Layer 3: Composite (should*)

| 함수명 | 파라미터 | 반환 | 의존 | 설명 | TC# |
|--------|----------|------|------|------|-----|
| `should{Action}` | `entity: Entity` | `boolean` | `is*, can*` | {동작 조건} | #5 |

#### Usage Map

| Helper | UI | API | Test |
|--------|-----|-----|------|
| `is{Condition}` | 조건부 필드 | - | Given |
| `can{Action}` | disabled 상태 | validation | When |
| `get{Value}` | 표시 값 | request body | Then |
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
   - Domain Entity → Client State 매핑
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

### 1. Domain & Entity
실제 코드 타입과 1:1 매칭

### 2. Invariant Helpers
Layer별 헬퍼 함수 명세 + Usage Map

### 3. Usecase
Input → Output 테이블 + 관련 헬퍼 함수

### 4. Component & States
컴포넌트 계층 + State 설계

### 5. Usecase-Component Integration
연결 지점 테이블 + 사용되는 헬퍼 함수

## Component & Code - Client
Entity 파일 내에 Invariant Helper 함수 포함

## Verification
⚠️ Integration Test 최우선
- Integration Tests (필수): TC 기반 테스트 + 헬퍼 함수 사용
- Unit Tests (필수): Invariant 헬퍼 함수별 단위 테스트
- E2E Tests (필요 시): 전체 플로우만
```

### Phase 5: 결과 보고

```
Design 완료!

Domain Model:
- Entities: {entity list}
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
| Linear 문서에 테스트 케이스가 없음 | 최소한의 Entity/Usecase를 제안하고 확인 요청 |
| Figma URL이 없음 | 테스트 케이스만으로 컴포넌트 설계 진행 |
| Linear 문서 업데이트 실패 | 에러 메시지 출력, 재시도 안내 |

## Example

```
사용자: /tdd:design

Claude: .claude/docs/에서 메타데이터 파일을 찾고 있습니다...
  → .claude/docs/my-feature/meta.yaml 발견

Claude: Linear에서 TechSpec 문서를 조회합니다...
  → document.id: abc123

Claude: 테스트 케이스를 분석하여 도메인 모델을 추출합니다...

Claude: Design 완료!
  Domain Model:
  - Entities: Cart, CartItem, Product
  - Usecases: AddToCart, RemoveFromCart, UpdateQuantity

  Client Architecture:
  - Pages: CartPage
  - Components: 8개
  - Shared: Button, QuantitySelector

  Linear Document: https://linear.app/daangn/document/fe-techspec-xxx (Design 섹션 추가됨)
```
