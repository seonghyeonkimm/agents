---
name: tdd/issues
description: TechSpec과 Design 문서를 기반으로 Linear에 blocker/related issue를 분류하여 생성
allowed-tools:
  - Read
  - Write
  - Glob
  - ToolSearch
  - AskUserQuestion
---

# TDD Issues Command

`/tdd:spec`과 `/tdd:design`의 결과물을 기반으로 Linear 프로젝트에 issue와 sub-issue를 생성한다.

## Prerequisites

- **필수**: `.claude/docs/{project-name}/meta.yaml` 존재 (`/tdd:spec` 실행 결과)
- **필수**: Linear TechSpec 문서에 `/tdd:spec` 결과물 포함 (Functional Requirements 섹션)
- **필수**: Linear TechSpec 문서에 `/tdd:design` 결과물 포함 (Design, Component & Code, Verification 섹션)
- **필수 MCP**: Linear plugin 활성화

## Execution Flow

### Phase 1: 메타데이터 로드 및 Linear 문서 검증

1. `.claude/docs/` 하위에서 프로젝트 메타데이터 파일을 찾는다:
   ```
   Glob(pattern: ".claude/docs/*/meta.yaml")
   ```
2. 여러 프로젝트가 있으면 AskUserQuestion으로 선택 요청
3. meta.yaml에서 `document.id`, `project.id` 등 메타데이터를 읽는다
4. Linear에서 TechSpec 문서 내용을 조회한다:
   ```
   ToolSearch(query: "select:mcp__plugin_linear_linear__get_document")
   → mcp__plugin_linear_linear__get_document(id: "{document.id}")
   ```
5. Linear 문서에서 **필수 섹션 존재 여부를 검증**한다:

**검증 체크리스트:**

| 섹션 | 출처 | 필수 여부 |
|------|------|----------|
| `## Functional Requirements` | `/tdd:spec` | 필수 |
| `## Design` | `/tdd:design` | 필수 |
| `### 1. Domain & Entity` | `/tdd:design` | 필수 |
| `### 2. Usecase` | `/tdd:design` | 필수 |
| `## Component & Code - Client` | `/tdd:design` | 필수 |
| `## Verification` | `/tdd:design` | 필수 |

**검증 실패 시:**
- `## Functional Requirements` 없음 → `/tdd:spec`을 먼저 실행하라고 안내
- `## Design` 없음 → `/tdd:design`을 먼저 실행하라고 안내

6. 검증 통과 시 Linear 문서에서 다음 정보를 추출한다:
   - Functional Requirements: Given/When/Then 테스트 케이스
   - Design: domain model, usecases, component tree

### Phase 2: Issue 분류

문서 내용을 분석하여 작업 단위를 **Blocker**와 **Related**로 분류한다.

**분류 기준:**

| 유형 | 기준 | 예시 |
|------|------|------|
| **Blocker** | 다른 작업의 선행 조건. 이것 없이 진행 불가 | API 설계, 공통 컴포넌트, Entity 정의, 인프라 셋업 |
| **Related** | 독립적으로 진행 가능. Blocker 완료 후 병렬 작업 | 개별 페이지 구현, 개별 Usecase 구현, 테스트 작성 |

**추출 소스 (Linear TechSpec 문서에서):**

- **Functional Requirements** → Acceptance Criteria 항목별 issue, Given/When/Then 테스트 케이스 그룹
- **Design** → Entity 정의, Usecase 구현, Component 구현, State 설계

**Issue 구조화 패턴:**

```
[Blocker] 공통 Entity/Type 정의
[Blocker] API 인터페이스 설계
[Blocker] 공통 컴포넌트 구현 ({shared components})
  └── [Sub] {SharedComponent1}
  └── [Sub] {SharedComponent2}
[Related] {PageName} 페이지 구현
  └── [Sub] {Usecase1} 구현
  └── [Sub] {Usecase2} 구현
  └── [Sub] {PageName} 테스트 작성
```

### Phase 3: 사용자 확인

분류 결과를 AskUserQuestion으로 제시하여 확인받는다:

```
question: "다음 issue 구조로 생성합니다. 수정할 항목이 있나요?"

Blocker Issues:
1. [Blocker] {issue title} - {description}
2. [Blocker] {issue title} - {description}

Related Issues:
3. [Related] {issue title}
   └── [Sub] {sub-issue title}
   └── [Sub] {sub-issue title}
4. [Related] {issue title}
   └── [Sub] {sub-issue title}
```

사용자가 수정을 요청하면 반영 후 다시 확인.

### Phase 3.5: Label 확인/생성

Issue 생성 전에 "ads-fe/tdd" label을 확인한다:

```
ToolSearch(query: "select:mcp__plugin_linear_linear__list_issue_labels")
list_issue_labels(team: "{team}", name: "tdd")
```

**조회 결과:**
- `"ads-fe/tdd"` label 있음 → Phase 4로 진행
- `"ads-fe/tdd"` label 없음 → 사용자에게 안내:
  ```
  ⚠️ "ads-fe/tdd" label이 Linear에 없습니다.
  Linear에서 다음 단계를 수행하세요:
  1. Project Settings → Labels
  2. "ads-fe/tdd" label 생성 (또는 생성 확인)
  3. 다시 /tdd:issues 실행
  ```

### Phase 4: Linear Issue 생성

MCP 도구를 로드하고 issue를 생성한다.

```
ToolSearch(query: "select:mcp__plugin_linear_linear__create_issue")
ToolSearch(query: "select:mcp__plugin_linear_linear__list_issue_labels")
```

**생성 순서:**

1. **Blocker issue 먼저 생성** (parent issues)
2. **Related issue 생성** (parent issues)
3. **Sub-issue 생성** (parent issue ID 참조)

**Issue 생성 시 포함할 내용:**

```
mcp__plugin_linear_linear__create_issue(
  title: "{issue title}",
  team: "{team from meta.yaml project}",
  description: """
{관련 AC, test cases, design 내용 요약}

## TDD Workflow (Red-Green-Refactor)

이 issue는 TDD 방식으로 구현합니다.

### 1. 🔴 Red - 실패하는 테스트 작성
- 위 Given/When/Then 테스트 케이스를 실제 테스트 코드로 작성
- 테스트 실행 → 실패 확인 (구현 전이므로 당연히 실패)

### 2. 🟢 Green - 최소 구현
- 테스트를 통과시키는 최소한의 코드 작성
- "동작하는 것"에만 집중, 완벽한 코드 X
- 테스트 실행 → 성공 확인

### 3. 🔵 Refactor - 리팩토링
- 테스트가 통과하는 상태에서 코드 품질 개선
- 중복 제거, 네이밍 개선, 구조 정리
- 테스트 실행 → 여전히 성공 확인

### Commit 전 필수 체크
```bash
npx tsc --noEmit     # Type check
npx biome check .    # Lint
npx vitest run       # Test
```
""",
  priority: {blocker=2(High), related=3(Medium)},
  labels: ["ads-fe/tdd"],
  project: "{project name or id}"
)
```

Sub-issue 생성 시:
```
mcp__plugin_linear_linear__create_issue(
  title: "{sub-issue title}",
  team: "{team}",
  description: "{상세 구현 내용}",
  parent: "{parent issue id}",
  labels: ["ads-fe/tdd"],
  project: "{project name or id}"
)
```

### Phase 5: 결과 보고

```
Issue 생성 완료!

Project: {Project Name}
Linear: {project url}
Label: ads-fe/tdd

Blocker Issues ({N}개):
- {issue title} ({linear url})

Related Issues ({N}개):
- {issue title} ({linear url})
  └── {sub-issue count}개 sub-issues

Total: {total}개 issues

---

📋 TDD 안내:
- 각 issue에는 Red-Green-Refactor 워크플로우가 포함되어 있습니다
- 테스트 먼저 작성 → 최소 구현 → 리팩토링 순서로 진행하세요

조회: list_issues(project: "{project-id}", labels: ["ads-fe/tdd"])

다음 단계:
- /tdd:implement: 병렬 워크스페이스로 자동 구현 시작
- 또는 Linear에서 담당자 배정 후 수동 TDD 진행
```

### Phase 6: /tdd:implement 연동

/tdd:implement는 다음과 같이 issues 생성 여부를 확인한다:

1. meta.yaml에서 project.id 읽기
2. Linear 조회: `list_issues(project: "{project-id}", labels: ["ads-fe/tdd"])`
3. "ads-fe/tdd" label issue 존재 여부 확인
   - 있음 → 구현 진행
   - 없음 → "/tdd:issues 먼저 실행하세요" 안내

### Phase 7: (Human) Review

사용자가 Linear에서 생성된 issue를 리뷰하고 담당자를 배정한다.

## Error Handling

| 상황 | 대응 |
|------|------|
| meta.yaml 없음 | `/tdd:spec`을 먼저 실행하라고 안내 |
| Linear 문서 조회 실패 | 사용자에게 Linear URL 안내, 수동 확인 요청 |
| `## Functional Requirements` 섹션 없음 | `/tdd:spec`을 먼저 실행하라고 안내 |
| `## Design` 섹션 없음 | `/tdd:design`을 먼저 실행하라고 안내 |
| Linear team 식별 불가 | AskUserQuestion으로 팀 선택 요청 |
| Issue 생성 중 실패 | 성공한 issue 목록을 보고하고, 실패 건 재시도 안내 |
| Label 'ads-fe/tdd'가 없음 | label 생성 안내 |

## Example

```
사용자: /tdd:issues

Claude: .claude/docs/my-feature/ 에서 메타데이터를 로드합니다...
  → meta.yaml 로드 (document.id: abc123)

Claude: Linear에서 TechSpec 문서를 조회합니다...
  → Functional Requirements (12개 테스트 케이스)
  → Design (entities: Cart, CartItem / usecases: 4개 / components: 8개)

Claude: [AskUserQuestion] 다음 issue 구조로 생성합니다:

  Blocker Issues:
  1. [Blocker] Cart Entity 및 Type 정의
  2. [Blocker] Cart API 인터페이스 설계
  3. [Blocker] 공통 컴포넌트 (QuantitySelector, Button)

  Related Issues:
  4. [Related] CartPage 구현
     └── AddToCart Usecase
     └── RemoveFromCart Usecase
     └── CartPage 테스트
  5. [Related] CartItem 컴포넌트 구현

사용자: 좋습니다

Claude: Linear에 issue를 생성합니다...

Claude: Issue 생성 완료!

  Blocker Issues (3개):
  - [Blocker] Cart Entity 및 Type 정의 (https://linear.com/issue/PROJ-1)
  - [Blocker] Cart API 인터페이스 설계 (https://linear.com/issue/PROJ-2)
  - [Blocker] 공통 컴포넌트 (QuantitySelector, Button) (https://linear.com/issue/PROJ-3)

  Related Issues (2개):
  - [Related] CartPage 구현 (https://linear.com/issue/PROJ-4)
    └── 3개 sub-issues
  - [Related] CartItem 컴포넌트 구현 (https://linear.com/issue/PROJ-5)

  Total: 9개 issues

  조회 방법: Linear에서 직접 확인하세요.
  다음 단계: /tdd:implement으로 병렬 워크스페이스 생성
```
