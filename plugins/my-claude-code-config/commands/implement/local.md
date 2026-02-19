---
name: implement/local
description: spec/design/issues 기반 구현을 현재 workspace에서 직접 실행. vibe_kanban 없이 동작하며, --issue로 Conductor 병렬 실행 지원
allowed-tools:
  - Read
  - Write
  - Edit
  - Glob
  - Grep
  - Bash
  - ToolSearch
  - AskUserQuestion
---

# Implement Local Command

`/tdd:spec`, `/tdd:design`, `/tdd:issues`의 결과물을 기반으로 현재 workspace에서 직접 구현한다.

**핵심 원칙: vibe_kanban 없이 동일한 TDD 워크플로우 (Red→Green→Refactor + Review Gate)**

`/tdd:implement`와 동일한 철학이지만, vibe_kanban workspace session 대신 현재 workspace에서 직접 실행한다. 순차 실행이 기본이며, `--issue` 파라미터로 Conductor 병렬 실행도 지원한다.

```
순차 실행:
  Issue 1: Red → Review → Green → Review → Refactor → Review → PR
  Issue 2: Red → Review → Green → Review → Refactor → Review → PR
  ...

병렬 실행 (Conductor):
  Workspace A: /implement:local --issue TEAM-101 → Red → Green → Refactor → PR
  Workspace B: /implement:local --issue TEAM-102 → Red → Green → Refactor → PR
  Workspace C: /implement:local --issue TEAM-103 → Red → Green → Refactor → PR
```

## Usage

```
/implement:local [--base <branch>] [--issue <linear-issue-id>]
```

### Parameters

| Parameter | Description | Example |
|-----------|-------------|---------|
| `--base <branch>` | PR의 target branch를 직접 지정. implement.yaml 설정을 override함 | `--base feature/new-cart` |
| `--issue <id>` | 특정 issue만 실행 (worker mode). 병렬 실행 시 각 Conductor workspace에서 사용 | `--issue TEAM-123` |

### Examples

```bash
# 기본 실행 (orchestrator: 첫 실행이면 batch 준비, 재실행이면 상태 확인)
/implement:local

# base branch 직접 지정
/implement:local --base feature/checkout

# 특정 issue만 실행 (worker mode — Conductor 병렬 실행용)
/implement:local --issue TEAM-123
```

## Prerequisites

- **필수**: `.claude/docs/{project-name}/meta.yaml` 존재 (`/tdd:spec` 실행 결과)
- **필수**: Linear TechSpec 문서에 `/tdd:design` 결과물 포함 (Design 섹션)
- **필수**: meta.yaml의 project.id로 Linear에서 "tdd" label issue 조회 가능 (`/tdd:issues`)
- **필수 MCP**: Linear plugin
- **불필요**: vibe_kanban

## Execution Flow

### Mode 분기

1. **파라미터 파싱**: `--base <branch>`, `--issue <id>` 저장
2. `--issue` 있으면 → **Worker Mode** (Phase W)로 분기
3. `--issue` 없으면 → **Orchestrator Mode** (Phase 1)로 진행

---

## Orchestrator Mode

### Phase 1: 메타데이터 로드 및 상태 확인

1. `.claude/docs/{project-name}/implement.yaml` 존재 여부 확인:
   - 파일이 없으면 → 첫 실행: Phase 2로 진행
   - 파일이 있으면 → **executor 필드 확인**:

   **executor: "local" 인 경우** → 현재 batch의 issue 상태 확인:
   ```
   implement.yaml의 현재 batch issues를 순회:
     status: "completed" → 건너뜀
     status: "in_progress" → 해당 issue의 phase부터 이어서 진행
     status: "pending" → 이전 issue가 모두 completed면 시작

   모든 issue completed → 다음 batch 있으면 진행 여부 AskUserQuestion, 없으면 "done"
   ```

   **executor: "vibe_kanban" 인 경우** → AskUserQuestion:
   ```
   question: "현재 implement.yaml은 /tdd:implement (vibe_kanban)로 진행 중입니다.

   완료된 issue는 유지하고, 미완료 issue를 local executor로 전환할까요?
   선택: 전환 / 중단"
   ```
   전환 시: executor를 "local"로 변경, 완료된 issue는 유지, 미완료 issue의 task_id 제거 후 status/phase 필드 추가

   `--base` 파라미터가 있으면 implement.yaml의 base_branch override

2. `.claude/docs/{project-name}/meta.yaml`에서 project.id를 추출한다

3. Linear에서 issue를 조회한다:
   ```
   ToolSearch(query: "select:mcp__plugin_linear_linear__list_issues")
   list_issues(project: "{project-id}", labels: ["tdd"])
   ```
   - 각 issue의 `id`와 `url`을 추출

4. 조회된 issue 목록을 Blocker/Related로 분류한다

5. 배치를 결정한다:
   ```
   Batch 1 (병렬 가능): [Blocker A] [Blocker B] [Blocker C]
     ↓ 완료 대기
   Batch 2 (병렬 가능): [Related D] [Related E] [Related F]
   ```

6. AskUserQuestion으로 실행할 배치를 확인

### Phase 2: Base Branch 설정

> 재실행(implement.yaml 존재) 시 이 Phase는 저장된 값을 사용하여 건너뜀

1. **Base Branch 지정** (우선순위: 파라미터 > implement.yaml > 대화형 입력):

   **1-1. 파라미터 확인 (최우선)**
   - `--base <branch>` 파라미터가 제공되었으면 → 해당 branch 사용

   **1-2. implement.yaml 존재 여부 확인**
   - 파일이 있으면 → `local.base_branch` 읽음 (재실행)

   **1-3. 첫 실행 시 사용자에게 base branch 물어보기**:
   ```
   AskUserQuestion:
     question: "이 implementation의 base branch를 지정하세요.

     현재 git branch: {current_branch}
     기본값: {current_branch}
     또는 다른 branch: [main / develop / feature/... / ...]"
   ```

### Phase 3: Issue별 Package 매핑

Linear issue description의 "작업 대상" 섹션에서 패키지 정보를 추출한다:

1. **Package 정보 추출**: Linear issue의 "작업 대상" 섹션에서 `package_name`, `package_path`, `target_directory`, `reference_pattern` 추출
2. 정보가 없으면 TechSpec Design 섹션의 "Component & Code" 파일 구조에서 직접 추출
3. 명확하지 않으면 AskUserQuestion으로 확인

### Phase 3.5: 현재 Batch의 Base Branch 결정

현재 batch에 따라 PR의 base branch를 결정한다:

**Batch 1 (첫 배치)**:
- `base_branch` = implement.yaml의 `local.base_branch`

**Batch 2+ (이전 배치 존재)**:
1. `gh pr list` 등으로 이전 batch의 PR/branch 정보 파악
2. 이전 batch에 issue가 **1개**면: 해당 issue의 branch를 base로 사용
3. 이전 batch에 issue가 **여러 개**면: 프로젝트 base branch 사용 (이전 batch PR들이 merge되었어야 함)
4. 판단이 어려우면: AskUserQuestion으로 사용자에게 확인

### Phase 4: Task Description 생성 & 실행 방식 선택

1. 각 issue에 대해 `.claude/docs/{project-name}/tasks/{issue-id}.md`에 standalone task description을 생성한다.

   Task description은 `/tdd:implement`의 "통합 Task Description 템플릿"과 동일한 구조를 사용하되, 변수를 실제 값으로 치환:

   ````
   🚫 **금지 사항 — 아래 규칙을 반드시 준수하세요:**
   - `Skill` 도구를 호출하지 마세요 (어떤 스킬이든 — `/tdd:start`, `/plan`, `/commit` 등 모두 금지)
   - `EnterPlanMode` 도구를 호출하지 마세요
   - PR 생성 시 `--base` 플래그를 반드시 아래 Context의 **Base Branch** 값으로 지정하세요. `main`을 base로 사용하지 마세요.
   - 아래 Step 1부터 순서대로 실행하세요. 각 Step 완료 후 Review Gate에서 반드시 멈추고 인간의 리뷰를 받으세요.

   ## Context

   - Linear Issue: {linear_issue_url}
   - TechSpec Document: {meta.yaml의 document.url}
   - **Base Branch**: `{base_branch}`
   - **작업 대상 패키지**: `{package_name}` (`{package_path}`)
   - **작업 디렉토리**: `{package_path}/{target_directory}`
   - **기존 패턴 참조**: `{package_path}/{reference_pattern}` (같은 패키지 내 유사 모듈)
   - **Linear Issue ID**: `{issue_id}` (Linear 동기화용)

   ## 관련 테스트 케이스

   {Linear TechSpec 문서에서 해당 issue의 Given/When/Then 테이블}

   ## 관련 설계

   {Linear TechSpec 문서의 Design 섹션에서 해당 데이터 모델(Interface)/Usecase/Component 정보}

   ---

   ## Step 1: 🔴 RED — 실패하는 테스트 작성

   이 Step의 목표는 **테스트만** 작성하고 **커밋 & 푸시**하는 것입니다.
   구현 코드를 작성하지 마세요.

   ### 작업 순서

   1. `{base_branch}`에서 브랜치 생성 (이름 규칙: issue title 기반 kebab-case)
   2. Given/When/Then 테스트 케이스를 실제 테스트 코드로 변환
      - ⚠️ `describe`/`it`/`test` 설명은 **한국어**로 작성
      - ⚠️ TC#, TC1 등 번호 접두사를 붙이지 않음 — 설명만 작성
      - ⚠️ UI 렌더링 자체를 검증하는 테스트는 지양. **사용자 행동**(클릭, 입력 등)과 그 **결과**(핸들러 호출, 상태 변경, 다른 컴포넌트 노출)를 검증하는 통합 테스트 위주로 작성
      - ❌ `it('RecommendCreateAd를 렌더링한다')` → ✅ `it('광고가 없을 때 클릭하면 onCreateAd가 호출된다')`
      - 예: `describe('PostAdListItem')`, `it('광고가 0개일 때 광고 생성 유도 영역을 클릭하면 onCreateAd가 호출된다')`
   3. 테스트 실행 → **실패 확인** (Red 상태)
   4. 커밋 & 푸시

   ### Linear 동기화

   ```
   ToolSearch(query: "select:mcp__plugin_linear_linear__update_issue")
   update_issue(id: "{issue_id}", state: "started")

   ToolSearch(query: "select:mcp__plugin_linear_linear__create_comment")
   create_comment(issueId: "{issue_id}", body: "🔴 Red Phase 완료 - 테스트 작성 완료")
   ```

   ### 완료 조건

   - [ ] 테스트 파일이 존재함
   - [ ] 테스트 실행 시 실패함 (구현이 없으므로)
   - [ ] 브랜치에 push됨

   ### 🔍 Review Gate 1

   **반드시 여기서 멈추고 AskUserQuestion으로 인간에게 리뷰를 요청하세요.**

   ```
   AskUserQuestion:
     question: "🔴 Red Phase 완료.

     브랜치: {branch_name}
     테스트 파일: {파일 경로 목록}
     실패하는 테스트: {N}개

     테스트 코드를 리뷰해주세요.
     선택: 진행 (Green으로) / 수정 요청 / 중단"
   ```

   - **수정 요청** 시 → 피드백에 따라 테스트 수정 → 커밋 & 푸시 → 다시 Review Gate 1
   - **진행** 시 → Step 2로
   - **중단** 시 → 작업 중지 (현재 상태 유지)

   ---

   ## Step 2: 🟢 GREEN — 테스트 통과시키기

   이 Step의 목표는 기존 테스트를 통과시키는 **최소한의 코드**를 작성하는 것입니다.
   과도한 추상화나 리팩토링을 하지 마세요.

   ### 작업 순서

   1. 기존 테스트 코드 확인
   2. 테스트를 통과시키는 **최소한의** 코드 작성
      - 조기 최적화 금지
      - 테스트에 없는 케이스 처리 금지
      - 리팩토링이나 코드 정리 금지
      - 필요 이상의 추상화 금지
   3. 테스트 실행 → **성공 확인** (Green 상태)
   4. 커밋 & 푸시

   ### Linear 동기화

   ```
   ToolSearch(query: "select:mcp__plugin_linear_linear__create_comment")
   create_comment(issueId: "{issue_id}", body: "🟢 Green Phase 완료")
   ```

   ### 완료 조건

   - [ ] 모든 테스트 통과
   - [ ] 최소한의 구현만 포함 (no gold plating)
   - [ ] 브랜치에 push됨

   ### 🔍 Review Gate 2

   **반드시 여기서 멈추고 AskUserQuestion으로 인간에게 리뷰를 요청하세요.**

   ```
   AskUserQuestion:
     question: "🟢 Green Phase 완료.

     변경 파일:
     - {file} - {변경 요약}

     모든 테스트 통과.
     선택: 진행 (Refactor로) / 수정 요청 / Refactor 건너뛰기 / 중단"
   ```

   - **수정 요청** 시 → 피드백에 따라 구현 수정 → 테스트 재실행 → 커밋 & 푸시 → 다시 Review Gate 2
   - **진행** 시 → Step 3로
   - **Refactor 건너뛰기** 시 → Draft PR 생성 + Linear 상태 업데이트 + `gh pr ready` 실행
   - **중단** 시 → 작업 중지

   ---

   ## Step 3: 🔵 REFACTOR — 리팩토링

   이 Step의 목표는 코드 품질을 개선하는 것입니다.

   ### 작업 순서

   1. 코드 품질 개선 (중복 제거, 네이밍, 구조 개선)
   2. Business Rules에 해당하는 반복 로직은 `entity-object-pattern` 스킬을 참조하여 Entity Object로 그룹화
   3. 테스트 실행 → **여전히 성공** 확인
   4. Pre-commit 체크:
      ```bash
      # 1. Type check
      npx tsc --noEmit

      # 2. Biome check
      npx biome check .

      # 3. Test
      npx vitest run
      ```
      실패 시 수정 후 재실행. 모두 통과해야 commit 가능.
   5. 커밋 & 푸시
   6. Draft PR 생성:
      ```bash
      gh pr create --draft --base {base_branch} \
        --title "{issue title}" \
        --body "$(cat <<'EOF'
      ## TDD Progress
      - [x] 🔴 Red: 실패하는 테스트 작성
      - [x] 🟢 Green: 최소 구현
      - [x] 🔵 Refactor: 코드 개선

      ### 리뷰 포인트
      - [ ] 테스트 케이스가 요구사항을 정확히 반영하는가?
      - [ ] 구현이 테스트 요구사항을 올바르게 충족하는가?
      - [ ] 코드 구조와 네이밍이 적절한가?
      EOF
      )"
      ```

      **중요**: `--base {base_branch}` 플래그 필수! `main`을 base로 사용하면 안 됩니다!

   ### Linear 동기화

   ```
   ToolSearch(query: "select:mcp__plugin_linear_linear__update_issue")
   # "In Review" 상태 ID 확인: list_issue_statuses(team: "{your-team}")에서
   # "In Review" name을 가진 상태의 id 사용
   update_issue(id: "{issue_id}", stateId: "{in-review-state-id}")

   ToolSearch(query: "select:mcp__plugin_linear_linear__create_comment")
   create_comment(issueId: "{issue_id}", body: "🔵 Refactor 완료 - 최종 리뷰: {pr_url}")
   ```

   > Note: "Done" 상태는 PR이 merge된 후 별도로 처리됩니다.

   ### 완료 조건

   - [ ] 모든 테스트 통과
   - [ ] tsc, biome 통과
   - [ ] 브랜치에 push됨
   - [ ] Draft PR 생성됨

   ### 🔍 Review Gate 3

   **반드시 여기서 멈추고 AskUserQuestion으로 인간에게 최종 리뷰를 요청하세요.**

   ```
   AskUserQuestion:
     question: "🔵 Refactor Phase 완료. Draft PR을 생성했습니다.

     PR: {pr_url}
     tsc: ✅ 통과
     biome: ✅ 통과
     테스트: ✅ 전체 통과

     선택: 승인 (PR을 Ready for Review로 전환) / 수정 요청"
   ```

   - **수정 요청** 시 → 피드백에 따라 수정 → 체크 재실행 → 커밋 & 푸시 → 다시 Review Gate 3
   - **승인** 시 → `gh pr ready {pr_number}` 실행 → 작업 완료
   ````

2. AskUserQuestion으로 실행 방식 선택:
   ```
   AskUserQuestion:
     question: "Batch {N} 준비 완료 ({count}개 issue)

     {issue 목록}

     Task description이 .claude/docs/{project-name}/tasks/ 에 생성되었습니다.

     실행 방식:
     - 순차: 현재 workspace에서 하나씩 처리합니다
     - 병렬: 각 issue를 별도 Conductor workspace에서 실행하세요
       /implement:local --issue {issue-id-1}
       /implement:local --issue {issue-id-2}
       /implement:local --issue {issue-id-3}"
   ```

### Phase 5: 순차 실행 (Orchestrator inline)

현재 batch의 issue를 **순서대로** 실행한다.

각 issue에 대해:

1. `.claude/docs/{project-name}/tasks/{issue-id}.md`를 Read하여 task description 로드
2. implement.yaml 업데이트: 해당 issue의 `status` → `"in_progress"`, `phase` → `"red"`
3. Task description의 Step 1~3 + Review Gate 1~3을 **직접 실행**
4. 각 phase 완료 시 implement.yaml의 `phase` 필드 업데이트:
   - Red 완료 → `phase: "red"`
   - Green 완료 → `phase: "green"`
   - Refactor 완료 → `phase: "refactor"`
5. 최종 승인(Review Gate 3) 후:
   - `gh pr ready {pr_number}` 실행
   - implement.yaml 업데이트: `status` → `"completed"`, `phase` → `"done"`, `branch`, `pr_url` 저장
6. 다음 issue가 있으면 AskUserQuestion:
   ```
   question: "Issue 완료: {title}
   PR: {pr_url}

   다음 issue: {next_title}
   진행할까요? (진행 / 중단)"
   ```

**중단 시**: 현재 상태가 implement.yaml에 저장되어 있으므로, 재실행(`/implement:local`) 시 이어서 진행 가능.

### Phase 6: 상태 저장

`.claude/docs/{project-name}/implement.yaml`에 실행 상태를 저장한다:

```yaml
# .claude/docs/{project-name}/implement.yaml
executor: "local"
project:
  id: "{project-id}"
  name: "{project-name}"
document:
  url: "{linear-document-url}"
local:
  base_branch: "{selected_base_branch}"
current_step:
  batch: 1                       # 현재 batch 번호
batches:
  - batch: 1
    type: blocker
    issues:
      - issue_id: "{linear-issue-id}"
        issue_url: "{linear-issue-url}"
        title: "{title}"
        package_name: "{package-name}"
        package_path: "{package-path}"
        target_directory: "{target-dir}"
        reference_pattern: "{ref-path}"
        status: "pending"         # pending | in_progress | completed
        phase: null               # red | green | refactor | done
        branch: null              # branch name (Red phase에서 생성)
        pr_url: null              # PR URL (Refactor phase에서 생성)
  - batch: 2
    type: related
    issues:
      - issue_id: "{linear-issue-id}"
        issue_url: "{linear-issue-url}"
        title: "{title}"
        package_name: "{package-name}"
        package_path: "{package-path}"
        target_directory: "{target-dir}"
        reference_pattern: "{ref-path}"
        status: "pending"
        phase: null
        branch: null
        pr_url: null
created_at: "{ISO-8601}"
```

**상태 저장 시점:**

- **Phase 전환 시**: `phase` 필드 업데이트 (red → green → refactor → done)
- **Issue 완료 시**: `status` → `"completed"`, `branch`, `pr_url` 저장
- **Batch 완료 확인 후** (재실행 시): `current_step.batch` → 다음 batch 번호로 업데이트

### Phase 7: 결과 보고

#### 순차 실행 - Issue 시작 시

```
Issue {N}/{total} 시작 (local executor, 순차)

Project: {Project Name}
TechSpec: {document URL}
Issue: {issue title}
Base Branch: {base_branch}
```

#### 병렬 실행 선택 시

```
Batch {N} 준비 완료 (병렬 실행)

Project: {Project Name}
TechSpec: {document URL}

각 Conductor workspace에서 실행하세요:
- /implement:local --issue {issue-id-1}  ← {title}
- /implement:local --issue {issue-id-2}  ← {title}
- /implement:local --issue {issue-id-3}  ← {title}

모든 issue 완료 후 /implement:local 로 다음 batch를 확인하세요.
```

#### 재실행 시 (상태 확인)

```
Batch {N} 상태 확인

- [{N}/{total}] {title} → ✅ completed (PR: {pr_url})
- [{N}/{total}] {title} → ⏳ in_progress (phase: {phase})
- [{N}/{total}] {title} → ⬜ pending

{다음 액션 안내}
```

#### Batch 전환 시

```
Batch {N} 모든 issue 완료!

다음: Batch {N+1} ({type} issues)
- {title}
- {title}

진행할까요?
```

---

## Worker Mode (Phase W)

`--issue <id>`로 실행된 경우 단일 issue만 처리한다. Conductor에서 병렬 실행할 때 각 workspace가 이 모드로 동작한다.

### Phase W1: 초기화

1. `.claude/docs/{project-name}/implement.yaml` 로드
   - implement.yaml이 없으면 → 에러: "먼저 /implement:local 을 실행하여 batch를 준비하세요"
2. `--issue <id>`에 해당하는 issue를 batches에서 찾기
   - 없으면 → 에러: "해당 issue를 찾을 수 없습니다" + 유효한 issue 목록 표시
3. issue의 현재 상태 확인:
   - `status: "completed"` → "이미 완료된 issue입니다" 안내
   - `status: "in_progress"` → AskUserQuestion: "이전 실행이 중단된 issue입니다. {phase} phase부터 이어서 진행할까요?"
   - `status: "pending"` → 실행 시작

### Phase W2: Task Description 로드

1. `.claude/docs/{project-name}/tasks/{issue-id}.md` 로드
   - 없으면 → 에러: "task description이 없습니다. /implement:local 을 먼저 실행하세요"

### Phase W3: 실행

1. implement.yaml에서 해당 issue의 `status` → `"in_progress"` 업데이트
2. task description의 Step 1~3 + Review Gate 1~3을 직접 실행
   - 이어서 진행하는 경우: 저장된 `phase`에 해당하는 Step부터 시작
   - 새로 시작하는 경우: Step 1 (Red)부터
3. 각 phase 완료 시 implement.yaml의 `phase` 업데이트
4. 최종 승인 후:
   - `gh pr ready {pr_number}` 실행
   - implement.yaml: `status` → `"completed"`, `phase` → `"done"`, `branch`, `pr_url` 저장

### Phase W4: 완료 보고

```
Issue 완료: {title}

Branch: {branch}
PR: {pr_url}

implement.yaml이 업데이트되었습니다.
모든 batch issue 완료 후 /implement:local 로 다음 batch를 확인하세요.
```

---

## Error Handling

| 상황 | 대응 |
|------|------|
| meta.yaml 없음 | `/tdd:spec`을 먼저 실행하라고 안내 |
| Linear issue 조회 실패 | `/tdd:issues`를 먼저 실행하라고 안내 |
| "tdd" label issue 없음 | `/tdd:issues`를 먼저 실행하라고 안내 |
| implement.yaml `executor: "vibe_kanban"` | AskUserQuestion으로 local 전환 여부 확인 |
| `--issue`로 실행했으나 implement.yaml 없음 | `/implement:local`을 먼저 실행하라고 안내 |
| `--issue`로 실행했으나 해당 issue 없음 | 에러 + 유효한 issue 목록 표시 |
| `--issue`로 실행했으나 이미 completed | "이미 완료된 issue입니다" 안내 |
| `--issue`로 실행했으나 다른 worker가 in_progress | AskUserQuestion: 이어서 진행할지 확인 |
| task description 파일 없음 | `/implement:local`을 먼저 실행하라고 안내 |
| 순차 실행 중 세션 중단 | implement.yaml에 phase 저장 → 재실행 시 이어서 진행 |
| Green phase 3회 시도 후 실패 | AskUserQuestion으로 접근 방법 논의 |
| 전체 테스트 회귀 | 어떤 기존 테스트가 깨졌는지 표시, 대응 방법 논의 |
| git push 실패 | 에러 표시, 수동 해결 안내 |
| 모든 구현 완료 (done) | "모든 배치가 완료되었습니다" 안내 |

## Example: Orchestrator 첫 실행 → 순차 실행

```
사용자: /implement:local

Claude: .claude/docs/my-feature/meta.yaml 에서 project.id를 로드합니다...
Claude: implement.yaml이 없습니다. 첫 실행입니다.
Claude: Linear에서 "tdd" label issue를 조회합니다...
  → 3 blockers, 2 related

Claude: [AskUserQuestion] base branch를 지정하세요.
  현재 git branch: feature/new-cart
  기본값: feature/new-cart

사용자: feature/new-cart

Claude: Task description 생성 중...
  → .claude/docs/my-feature/tasks/TEAM-101.md
  → .claude/docs/my-feature/tasks/TEAM-102.md
  → .claude/docs/my-feature/tasks/TEAM-103.md

Claude: [AskUserQuestion] Batch 1 준비 완료 (3개 issue)

  1. Cart Interface 및 상수 정의
  2. Cart UI Component
  3. Cart API 엔드포인트

  실행 방식:
  - 순차: 현재 workspace에서 하나씩 처리
  - 병렬: 각 Conductor workspace에서 실행
    /implement:local --issue TEAM-101
    /implement:local --issue TEAM-102
    /implement:local --issue TEAM-103

사용자: 순차

Claude: Issue 1/3 시작: Cart Interface 및 상수 정의
(Step 1: Red phase 실행...)
...Review Gate 1...
(Step 2: Green phase 실행...)
...Review Gate 2...
(Step 3: Refactor phase 실행...)
...Review Gate 3...

사용자: 승인

Claude: Issue 1/3 완료!
  Branch: feat/cart-interface
  PR: https://github.com/...

  [AskUserQuestion] 다음 issue(Cart UI Component)로 진행할까요?

사용자: 진행

Claude: Issue 2/3 시작: Cart UI Component
...
```

## Example: 병렬 실행 (Conductor)

```
사용자: /implement:local

Claude: (... 동일한 setup ...)

Claude: [AskUserQuestion] Batch 1 준비 완료 (3개 issue)
  실행 방식: 순차 / 병렬

사용자: 병렬

Claude:
  Batch 1 준비 완료 (병렬 실행)

  각 Conductor workspace에서 실행하세요:
  - /implement:local --issue TEAM-101  ← Cart Interface 및 상수 정의
  - /implement:local --issue TEAM-102  ← Cart UI Component
  - /implement:local --issue TEAM-103  ← Cart API 엔드포인트

  모든 issue 완료 후 /implement:local 로 다음 batch를 확인하세요.
```

```
(Conductor Workspace A)
사용자: /implement:local --issue TEAM-101

Claude: implement.yaml 로드... Issue: Cart Interface 및 상수 정의
Claude: Task description 로드... .claude/docs/my-feature/tasks/TEAM-101.md
Claude: Step 1 (Red) 시작...
...Review Gate 1...
...
...Review Gate 3...
사용자: 승인
Claude: Issue 완료! PR: https://github.com/...
```

## Example: 재실행 → 상태 확인 → Batch 2

```
사용자: /implement:local

Claude: implement.yaml 발견 (executor: local)
Claude: Batch 1 상태 확인

  - [1/3] Cart Interface 및 상수 정의 → ✅ completed (PR: https://...)
  - [2/3] Cart UI Component → ✅ completed (PR: https://...)
  - [3/3] Cart API 엔드포인트 → ✅ completed (PR: https://...)

Claude: Batch 1 모든 issue 완료!

Claude: [AskUserQuestion] Batch 2를 시작할까요?

  Batch 2 (Related issues, 2개)
  - Wishlist 저장 기능
  - Cart 미니 뷰

  실행 방식: 순차 / 병렬

사용자: 순차로 진행

Claude: Issue 1/2 시작: Wishlist 저장 기능
...
```

## 참고

- **동일 철학**: `/tdd:implement`와 동일한 batch 기반 Red→Green→Refactor + Review Gate 패턴
- **vibe_kanban 불필요**: Linear plugin만으로 동작
- **병렬 실행**: Conductor의 멀티 workspace를 활용한 수동 병렬화 (`--issue`)
- **상태 추적**: implement.yaml의 per-issue `status`/`phase` 필드로 중단/재개 지원
- **implement.yaml 호환**: `/tdd:implement`와 동일 파일 사용, `executor` 필드로 구분
- **task description**: `.claude/docs/{project-name}/tasks/{issue-id}.md`에 standalone 파일로 저장
