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

- **필수**: `/tdd:spec` 실행 완료 → `.claude/docs/{project-name}/spec.md` 존재
- **필수 스킬**: `fe-techspec` - 설계 패턴 참조
- **선택 MCP**: Figma plugin (컴포넌트 상세 분석 시)

## Execution Flow

### Phase 1: Spec 로드

1. `.claude/docs/` 하위에서 프로젝트 spec 파일을 찾는다:
   ```
   Glob(pattern: ".claude/docs/*/spec.md")
   ```
2. 여러 프로젝트가 있으면 AskUserQuestion으로 선택 요청
3. spec.md의 frontmatter에서 메타데이터, 본문에서 TechSpec 내용을 읽는다

### Phase 2: Domain Entity & Usecase 추출

spec.md의 **Functional Requirements (Given/When/Then)** 섹션을 분석하여:

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
- **속성**: {property}: {type}
- **불변식**: {invariant description}

### Usecases

#### {UsecaseName}
- **Actor**: {who triggers}
- **Input**: {input params}
- **Output**: {output/side effects}
- **Entity**: {related entities}
- **Test Cases**: #{test case numbers}
```

### Phase 3: Client Component & State 설계

spec.md의 테스트 케이스 + Figma 디자인 (sources.figma가 있는 경우)을 기반으로:

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

### Phase 4: 결과 저장

spec.md 파일에 Design 섹션을 추가한다:

1. **Edit으로 spec.md 업데이트**
   - Functional Requirements 섹션 뒤에 다음 섹션 추가:
     - Design (Domain & Entity, Usecase, Component & States, Integration)
     - Component & Code - Client
     - Verification

2. **spec.md frontmatter의 `spec` 섹션에 entities, commands 추가**:
   ```yaml
   spec:
     entities: ["{Entity1}", "{Entity2}"]
     commands: ["{Command1}", "{Command2}"]
     test_case_count: {N}
     acceptance_criteria_count: {N}
   ```

**추가되는 섹션 형식:**

```markdown
## Design

### 1. Domain & Entity
실제 코드 타입과 1:1 매칭

### 2. Usecase
Input → Output 테이블

### 3. Component & States
컴포넌트 계층 + State 설계

### 4. Usecase-Component Integration
연결 지점 테이블

## Component & Code - Client
파일 구조, 컴포넌트 분해

## Verification
⚠️ Integration Test 최우선
- Integration Tests (필수): TC 기반 테스트 테이블
- Unit Tests (필요 시): 복잡한 로직만
- E2E Tests (필요 시): 전체 플로우만
```

### Phase 5: Linear 문서 업데이트

spec.md frontmatter의 `document.id`로 TechSpec 문서에 Design 섹션을 추가한다:

```
ToolSearch(query: "select:mcp__plugin_linear_linear__update_document")
→ Design, Component & Code, Verification 섹션 추가
```

### Phase 6: 결과 보고

```
Design 완료!

Domain Model:
- Entities: {entity list}
- Usecases: {usecase list}

Client Architecture:
- Pages: {page list}
- Components: {N}개
- Shared: {shared component list}

Local: .claude/docs/{project-name}/spec.md (Design 섹션 추가됨)
Linear: {document URL} (Design 섹션 업데이트됨)

다음 단계:
1. 설계를 리뷰하세요
2. /tdd:issues 로 Linear 이슈를 생성하세요
```

### Phase 7: (Human) Review

사용자가 도메인 모델과 컴포넌트 설계를 리뷰한다.

## Error Handling

| 상황 | 대응 |
|------|------|
| spec.md가 없음 | `/tdd:spec`을 먼저 실행하라고 안내 |
| spec.md에 테스트 케이스가 없음 | 최소한의 Entity/Usecase를 제안하고 확인 요청 |
| Figma URL이 없음 | 테스트 케이스만으로 컴포넌트 설계 진행 |
| Linear 문서 업데이트 실패 | 로컬 파일은 저장, 수동 복사 안내 |

## Example

```
사용자: /tdd:design

Claude: .claude/docs/에서 spec 파일을 찾고 있습니다...
  → .claude/docs/my-feature/spec.md 발견

Claude: 테스트 케이스를 분석하여 도메인 모델을 추출합니다...

Claude: Design 완료!
  Domain Model:
  - Entities: Cart, CartItem, Product
  - Usecases: AddToCart, RemoveFromCart, UpdateQuantity

  Client Architecture:
  - Pages: CartPage
  - Components: 8개
  - Shared: Button, QuantitySelector

  Local: .claude/docs/my-feature/spec.md (Design 섹션 추가됨)
```
