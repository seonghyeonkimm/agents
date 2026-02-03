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

- **필수**: `.claude/docs/{project-name}/spec.md` 존재
- **필수**: `spec.md`에 `/tdd:spec` 결과물 포함 (Functional Requirements 섹션)
- **필수**: `spec.md`에 `/tdd:design` 결과물 포함 (Design, Component & Code, Verification 섹션)
- **필수 MCP**: Linear plugin 활성화

## Execution Flow

### Phase 1: 문서 로드 및 검증

1. `.claude/docs/` 하위에서 프로젝트 디렉토리를 찾는다:
   ```
   Glob(pattern: ".claude/docs/*/spec.md")
   ```
2. 여러 프로젝트가 있으면 AskUserQuestion으로 선택 요청
3. spec.md를 읽고 **필수 섹션 존재 여부를 검증**한다:

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

4. 검증 통과 시 spec.md에서 다음 정보를 추출한다:
   - frontmatter: entities, commands, test_case_count
   - Functional Requirements: Given/When/Then 테스트 케이스
   - Design: domain model, usecases, component tree

### Phase 2: Issue 분류

문서 내용을 분석하여 작업 단위를 **Blocker**와 **Related**로 분류한다.

**분류 기준:**

| 유형 | 기준 | 예시 |
|------|------|------|
| **Blocker** | 다른 작업의 선행 조건. 이것 없이 진행 불가 | API 설계, 공통 컴포넌트, Entity 정의, 인프라 셋업 |
| **Related** | 독립적으로 진행 가능. Blocker 완료 후 병렬 작업 | 개별 페이지 구현, 개별 Usecase 구현, 테스트 작성 |

**추출 소스:**

- **spec.md** → Acceptance Criteria 항목별 issue, Given/When/Then 테스트 케이스 그룹
- **design.md** → Entity 정의, Usecase 구현, Component 구현, State 설계

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
  team: "{team from spec.md project}",
  description: "{관련 AC, test cases, design 내용 요약}",
  priority: {blocker=2(High), related=3(Medium)},
  labels: ["TechSpec"],
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
  project: "{project name or id}"
)
```

### Phase 5: 결과 보고

```
Issue 생성 완료!

Project: {Project Name}
Linear: {project url}

Blocker Issues ({N}개):
- {issue title} ({linear url})

Related Issues ({N}개):
- {issue title} ({linear url})
  └── {sub-issue count}개 sub-issues

Total: {total}개 issues

---

조회 방법: Linear에서 직접 확인하거나
`list_issues(project: "{project-id}")` 로 조회

다음 단계: /tdd:implement 또는 Linear에서 담당자 배정
```

### Phase 6: /tdd:implement 연동

/tdd:implement는 다음과 같이 issues 생성 여부를 확인한다:

1. spec.md에서 project.id 읽기
2. Linear 조회: `list_issues(project: "{project-id}")`
3. [TDD] 또는 [Blocker] prefix issue 존재 여부 확인
   - 있음 → 구현 진행
   - 없음 → "/tdd:issues 먼저 실행하세요" 안내

### Phase 7: (Human) Review

사용자가 Linear에서 생성된 issue를 리뷰하고 담당자를 배정한다.

## Error Handling

| 상황 | 대응 |
|------|------|
| spec.md 없음 | `/tdd:spec`을 먼저 실행하라고 안내 |
| `## Functional Requirements` 섹션 없음 | `/tdd:spec`을 먼저 실행하라고 안내 |
| `## Design` 섹션 없음 | `/tdd:design`을 먼저 실행하라고 안내 |
| Linear team 식별 불가 | AskUserQuestion으로 팀 선택 요청 |
| Issue 생성 중 실패 | 성공한 issue 목록을 보고하고, 실패 건 재시도 안내 |
| Label 'TechSpec'이 없음 | label 없이 생성하거나 새 label 생성 |

## Example

```
사용자: /tdd:issues

Claude: .claude/docs/my-feature/ 에서 문서를 로드합니다...
  → spec.md 로드 (entities: Cart, CartItem / test cases: 12개)
  → design.md 로드 (usecases: 4개 / components: 8개)

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
