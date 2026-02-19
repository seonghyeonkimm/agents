---
name: tdd/sync
description: 주어진 요구사항을 이해하고, tdd:* command로 생성된 문서들에 잘 반영되어 있는지 체크하고 누락분을 보고/반영
arguments:
  - name: requirements
    description: 요구사항 텍스트, Notion URL, 또는 Figma URL. 비어있으면 대화형으로 입력
    required: false
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - ToolSearch
  - AskUserQuestion
---

# TDD Sync Command

요구사항(신규/변경)을 tdd:* 워크플로우로 생성된 Linear 문서 및 이슈와 대조하여, 누락/불일치 항목을 찾아 보고하고 사용자 승인 후 반영한다.

## Prerequisites

- **필수**: `.claude/docs/{project-name}/meta.yaml` 존재 (`/tdd:spec` 실행 결과)
- **필수**: Linear TechSpec 문서에 최소 `/tdd:spec` 결과물 포함
- **필수 MCP**: Linear plugin 활성화
- **선택 MCP**: Notion plugin (PRD URL 제공 시), Figma plugin (디자인 URL 제공 시)

## Execution Flow

### Phase 1: 요구사항 수집

1. **입력 파싱**: `$ARGUMENTS.requirements` 분석

   | 입력 타입 | 감지 방법 | 처리 |
   |-----------|-----------|------|
   | 없음 | `$ARGUMENTS.requirements` 비어있음 | AskUserQuestion으로 입력 요청 |
   | 일반 텍스트 | URL 패턴 아님 | 그대로 요구사항으로 사용 |
   | Notion URL | `notion.so` 또는 `notion.site` 포함 | Notion MCP로 fetch |
   | Figma URL | `figma.com` 포함 | Figma MCP로 fetch |
   | 복합 입력 | 텍스트 + URL 혼합 | 각각 처리 후 합산 |

2. **Notion PRD fetch** (URL 제공 시):
   ```
   ToolSearch(query: "select:mcp__plugin_Notion_notion__notion-fetch")
   → mcp__plugin_Notion_notion__notion-fetch(url: "{notion_url}")
   ```
   - 핵심 요구사항, 유저 스토리, 변경 사항을 추출

3. **Figma 디자인 fetch** (URL 제공 시):
   ```
   ToolSearch(query: "select:mcp__plugin_figma_figma__get_design_context")
   → mcp__plugin_figma_figma__get_design_context(url: "{figma_url}")
   ```
   - 컴포넌트 구조, UI 변경 사항을 추출

4. **요구사항 정리**: 수집된 모든 소스에서 요구사항을 구조화한다:
   - 각 요구사항에 고유 ID 부여 (REQ-1, REQ-2, ...)
   - 유형 분류: 기능 추가 / 기능 변경 / 버그 수정 / 비기능

### Phase 2: 기존 문서 로드

1. `.claude/docs/` 하위에서 프로젝트 메타데이터 파일을 찾는다:
   ```
   Glob(pattern: ".claude/docs/*/meta.yaml")
   ```
2. 여러 프로젝트가 있으면 AskUserQuestion으로 선택 요청

3. meta.yaml에서 `document.id`, `project.id`, `sources` 등 메타데이터를 읽는다

4. **Linear TechSpec 문서 조회**:
   ```
   ToolSearch(query: "select:mcp__plugin_linear_linear__get_document")
   → mcp__plugin_linear_linear__get_document(id: "{document.id}")
   ```

5. 문서에서 각 섹션 존재 여부와 내용을 파악한다:

   | 섹션 | 출처 | 파악할 내용 |
   |------|------|------------|
   | Summary | `/tdd:spec` | 프로젝트 배경, 링크 |
   | Solution | `/tdd:spec` | 핵심 변경사항 목록 |
   | Acceptance Criteria | `/tdd:spec` | 테스트 가능한 기준 |
   | Functional Requirements | `/tdd:spec` | Given/When/Then 테스트 케이스 |
   | Design | `/tdd:design` | 데이터 모델, Business Rules, Usecases |
   | Component & Code | `/tdd:design` | 컴포넌트 트리, State 설계 |
   | Verification | `/tdd:design` | Integration/Unit/E2E 테스트 목록 |

6. **Linear 이슈 조회** (meta.yaml에 project.id가 있고, 이슈가 생성된 경우):
   ```
   ToolSearch(query: "select:mcp__plugin_linear_linear__list_issues")
   → list_issues(project: "{project-id}", labels: ["tdd"])
   ```
   - 각 이슈의 title, description에서 커버하는 테스트 케이스/유즈케이스를 파악

7. **Implementation 상태 확인** (implement.yaml 존재 시):
   ```
   Read(".claude/docs/{project-name}/implement.yaml")
   ```
   - 현재 batch, 진행 중인 task 파악
   - 이미 구현 완료된 이슈와 진행 중인 이슈 구분

### Phase 3: 갭 분석

요구사항(Phase 1)을 기존 문서(Phase 2)의 각 레이어와 대조한다.

**분석 레이어:**

#### 3-1. TechSpec 레이어 (tdd:spec 결과물)

| 체크 항목 | 판단 기준 |
|----------|----------|
| Solution 반영 | 요구사항이 Solution의 핵심 변경사항에 포함되어 있는가? |
| AC 반영 | 요구사항에 대응하는 Acceptance Criteria가 있는가? |
| TC 반영 | 요구사항에 대응하는 Given/When/Then 테스트 케이스가 있는가? |
| TC 충분성 | 정상/에러/엣지 케이스가 모두 커버되는가? |

#### 3-2. Design 레이어 (tdd:design 결과물)

| 체크 항목 | 판단 기준 |
|----------|----------|
| 데이터 모델 | 요구사항에서 참조하는 데이터가 interface에 정의되어 있는가? |
| Business Rules | 요구사항의 비즈니스 규칙이 BR 목록에 포함되어 있는가? |
| Usecase | 요구사항의 사용자 행동이 Usecase로 정의되어 있는가? |
| Component | 요구사항의 UI 변경이 컴포넌트 설계에 반영되어 있는가? |
| Verification | 요구사항에 대한 테스트가 Verification 섹션에 있는가? |

#### 3-3. Issues 레이어 (tdd:issues 결과물)

| 체크 항목 | 판단 기준 |
|----------|----------|
| 이슈 커버리지 | 새 요구사항을 구현할 이슈가 존재하는가? |
| 이슈 상세 | 기존 이슈의 description에 변경된 요구사항이 반영되어 있는가? |

#### 3-4. Implementation 레이어 (tdd:implement 결과물, 있는 경우)

| 체크 항목 | 판단 기준 |
|----------|----------|
| 완료된 이슈 충돌 | 이미 구현 완료된 이슈에 영향을 주는 변경인가? |
| 진행 중 이슈 영향 | 현재 진행 중인 이슈의 요구사항이 변경되었는가? |

**분류 결과:**

각 요구사항-문서 조합에 대해 상태를 부여한다:

| 상태 | 의미 |
|------|------|
| `OK` | 이미 반영됨 |
| `MISSING` | 문서에 해당 내용이 없음 (추가 필요) |
| `OUTDATED` | 문서에 있으나 요구사항과 불일치 (수정 필요) |
| `CONFLICT` | 이미 구현 완료된 부분과 충돌 (주의 필요) |

### Phase 4: 리뷰 보고

갭 분석 결과를 AskUserQuestion으로 보고한다:

```
AskUserQuestion:
  question: "요구사항 반영 상태를 분석했습니다.

  ## 요구사항 목록
  - REQ-1: {요구사항 설명}
  - REQ-2: {요구사항 설명}

  ## 반영 상태

  ### TechSpec (tdd:spec)
  | 요구사항 | Solution | AC | TC | 상태 |
  |---------|---------|-----|-----|------|
  | REQ-1 | OK | OK | MISSING | 테스트 케이스 추가 필요 |
  | REQ-2 | MISSING | MISSING | MISSING | 전체 추가 필요 |

  ### Design (tdd:design)
  | 요구사항 | Data Model | BR | Usecase | Component | 상태 |
  |---------|-----------|-----|---------|-----------|------|
  | REQ-1 | OK | OK | OK | MISSING | 컴포넌트 설계 추가 필요 |

  ### Issues (tdd:issues)
  | 요구사항 | 관련 이슈 | 상태 |
  |---------|---------|------|
  | REQ-1 | PROJ-5 | OUTDATED (description 업데이트 필요) |
  | REQ-2 | - | MISSING (새 이슈 필요) |

  ### Implementation 영향 (tdd:implement)
  | 이슈 | 구현 상태 | 영향 |
  |------|---------|------|
  | PROJ-3 | completed | CONFLICT (변경 필요, 별도 이슈 권장) |

  ---

  ## 제안 액션

  1. [TechSpec] REQ-1 테스트 케이스 추가: {구체적 내용}
  2. [TechSpec] REQ-2 전체 섹션 추가: {구체적 내용}
  3. [Design] REQ-1 컴포넌트 설계 보완: {구체적 내용}
  4. [Issue] PROJ-5 description 업데이트: {구체적 내용}
  5. [Issue] REQ-2 새 이슈 생성: {구체적 내용}
  6. [Warning] PROJ-3 이미 구현 완료 — 별도 수정 이슈 필요

  선택: 전체 승인 / 부분 승인 (번호 지정) / 수정 요청 / 중단"
```

### Phase 5: (Human) Approve

사용자가 리뷰 후 선택한다:
- **전체 승인** → Phase 6에서 모든 액션 실행
- **부분 승인** → 지정된 번호만 Phase 6에서 실행
- **수정 요청** → 피드백 반영 후 Phase 4 재실행
- **중단** → 작업 중지

### Phase 6: 반영

승인된 액션을 실행한다.

#### 6-1. TechSpec 문서 업데이트

```
ToolSearch(query: "select:mcp__plugin_linear_linear__get_document")
→ 현재 문서 내용 조회

ToolSearch(query: "select:mcp__plugin_linear_linear__update_document")
→ mcp__plugin_linear_linear__update_document(
    id: "{document.id}",
    content: "{갱신된 전체 문서 내용}"
  )
```

**업데이트 원칙:**
- 기존 내용을 최대한 유지하면서 누락분만 추가/수정
- Solution: 새 변경사항 항목 추가
- AC: 새 기준 추가
- Functional Requirements: 새 Given/When/Then 행 추가 또는 기존 행 수정
- Design: 데이터 모델/BR/Usecase/Component 해당 섹션 보완
- Verification: 새 테스트 항목 추가

#### 6-2. Linear 이슈 업데이트

기존 이슈 description 수정:
```
ToolSearch(query: "select:mcp__plugin_linear_linear__update_issue")
→ update_issue(id: "{issue-id}", description: "{갱신된 description}")
```

새 이슈 생성 (필요 시):
```
ToolSearch(query: "select:mcp__plugin_linear_linear__create_issue")
→ create_issue(
    title: "{issue title}",
    team: "{team}",
    description: "{description with TDD workflow}",
    labels: ["tdd"],
    project: "{project name or id}"
  )
```

#### 6-3. 충돌 이슈 생성

이미 구현 완료된 이슈와 충돌하는 변경은 별도 수정 이슈로 생성한다:
```
create_issue(
  title: "[Hotfix] {변경 설명}",
  team: "{team}",
  description: "기존 구현({원본 이슈 URL})에 대한 요구사항 변경...",
  labels: ["tdd"],
  project: "{project name or id}"
)
```

### Phase 6.5: 반영 검증

업데이트된 리소스를 다시 조회하여 정상 반영 여부를 확인한다.

1. **Linear 문서 재조회**:
   ```
   mcp__plugin_linear_linear__get_document(id: "{document.id}")
   ```
   - 추가/수정한 섹션이 문서에 존재하는지 확인

2. **이슈 검증** (이슈를 생성/수정한 경우):
   ```
   list_issues(project: "{project-id}", labels: ["tdd"])
   ```
   - 새로 생성한 이슈가 조회되는지 확인
   - "tdd" label이 붙어있는지 확인

3. **검증 실패 시**: 실패한 항목을 보고하고 재시도 안내

### Phase 7: 결과 보고

```
요구사항 동기화 완료!

Project: {Project Name}
TechSpec: {document URL}

반영된 액션:
- [TechSpec] {N}개 섹션 업데이트
- [Issue] {N}개 이슈 업데이트, {N}개 새 이슈 생성
- [Warning] {N}개 충돌 이슈 생성

업데이트된 리소스:
- Linear Document: {document URL}
- 업데이트된 이슈: {issue URLs}
- 새로 생성된 이슈: {issue URLs}

다음 단계:
1. Linear에서 업데이트된 문서를 확인하세요
2. 새 이슈가 있다면 /tdd:implement 로 구현을 시작하세요
```

### Phase 8: (Human) Review

사용자가 Linear에서 업데이트된 문서와 이슈를 리뷰하고 내용이 올바른지 확인한다.

## Error Handling

| 상황 | 대응 |
|------|------|
| meta.yaml 없음 | `/tdd:spec`을 먼저 실행하라고 안내 |
| Linear 문서 조회 실패 | 사용자에게 Linear URL 안내, 수동 확인 요청 |
| TechSpec만 있고 Design 없음 | TechSpec 레이어만 분석, Design은 `/tdd:design` 실행 안내 |
| Issues 없음 | TechSpec + Design 레이어만 분석, Issues는 `/tdd:issues` 실행 안내 |
| Notion/Figma fetch 실패 | 텍스트로 요구사항 직접 입력 요청 |
| Linear 문서 업데이트 실패 | 에러 메시지 출력, 수동 반영 안내 |
| 이슈 업데이트/생성 실패 | 성공한 항목 보고, 실패 건 재시도 안내 |
| 요구사항이 비어있음 | AskUserQuestion으로 입력 요청 |
| 모든 요구사항이 이미 반영됨 | "모든 요구사항이 이미 반영되어 있습니다" 안내 |
| implement.yaml 파싱 실패 | 경고 표시 후 Implementation 레이어 분석 건너뜀 |

## Example

```
사용자: /tdd:sync 결제 시 쿠폰 적용 기능 추가

Claude: .claude/docs/에서 메타데이터를 로드합니다...
  → .claude/docs/checkout/meta.yaml 발견

Claude: Linear에서 TechSpec 문서를 조회합니다...
  → document.id: abc123

Claude: 요구사항을 분석하고 기존 문서와 대조합니다...

Claude: [AskUserQuestion] 요구사항 반영 상태:

  ## 요구사항
  - REQ-1: 결제 시 쿠폰 코드 입력 필드 추가
  - REQ-2: 쿠폰 적용 시 할인 금액 실시간 반영
  - REQ-3: 유효하지 않은 쿠폰 코드 에러 처리

  ## 반영 상태

  ### TechSpec
  | 요구사항 | Solution | AC | TC | 상태 |
  |---------|---------|-----|-----|------|
  | REQ-1 | MISSING | MISSING | MISSING | 전체 추가 필요 |
  | REQ-2 | MISSING | MISSING | MISSING | 전체 추가 필요 |
  | REQ-3 | MISSING | MISSING | MISSING | 전체 추가 필요 |

  ### Design
  | 요구사항 | Data Model | BR | Usecase | Component | Verification | 상태 |
  |---------|-----------|-----|---------|-----------|-------------|------|
  | REQ-1 | MISSING | MISSING | MISSING | MISSING | MISSING | 전체 추가 필요 |

  ### Issues
  - 관련 이슈 없음

  제안 액션:
  1. [TechSpec] 쿠폰 관련 Solution/AC/TC 전체 추가
  2. [Design] CouponData 모델, ApplyCoupon Usecase, CouponInput 컴포넌트 추가
  3. [Issue] 쿠폰 기능 이슈 생성 (Blocker: 쿠폰 API, Related: UI 구현)

  선택: 전체 승인 / 부분 승인 / 수정 요청 / 중단

사용자: 전체 승인

Claude: Linear 문서를 업데이트합니다...
  → TechSpec: Solution, AC, Functional Requirements 추가
  → Design: 데이터 모델, Usecase, Component 추가

Claude: Linear 이슈를 생성합니다...
  → [Blocker] 쿠폰 API 인터페이스 (PROJ-10)
  → [Related] 쿠폰 적용 UI 구현 (PROJ-11)

Claude:
  요구사항 동기화 완료!

  반영된 액션:
  - [TechSpec] 3개 섹션 업데이트 (Solution, AC, TC)
  - [Design] 3개 섹션 업데이트 (Data Model, Usecase, Component)
  - [Issue] 2개 새 이슈 생성

  Linear Document: https://linear.app/daangn/document/fe-techspec-xxx
  새 이슈: PROJ-10, PROJ-11

  다음 단계:
  1. Linear에서 업데이트된 문서를 확인하세요
  2. /tdd:implement 로 구현을 시작하세요
```
