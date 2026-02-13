---
name: tdd/implement
description: spec/design/issues 기반으로 단일 Task 내에서 Red→Green→Refactor를 순차 실행. 각 phase 완료 후 인간 리뷰를 거침
allowed-tools:
  - Read
  - Write
  - Glob
  - Bash
  - ToolSearch
  - AskUserQuestion
---

# TDD Implement Command

`/tdd:spec`, `/tdd:design`, `/tdd:issues`의 결과물을 기반으로 구현을 시작한다.

**핵심 원칙: 단일 Task, 순차 Phase, Human-in-the-Loop**

각 issue당 하나의 vk task를 생성하고, Red→Green→Refactor를 순차적으로 실행한다.
각 phase 완료 후 인간이 PR에서 리뷰한 뒤 다음 phase를 진행한다.

```
Red    → Draft PR 생성 (테스트만)       → Human: PR에서 테스트 리뷰
Green  → 같은 PR에 구현 push            → Human: PR에서 구현 리뷰
Refactor → 같은 PR에 리팩토링 push      → Human: PR에서 최종 리뷰
최종 승인 → Draft PR → Ready for Review (open)
```

## Usage

```
/tdd:implement [--base <branch>] [--phase <red|green|refactor>]
```

### Parameters

| Parameter | Description | Example |
|-----------|-------------|---------|
| `--base <branch>` | PR의 target branch를 직접 지정. implement.yaml 설정을 override함 | `--base feature/new-cart` |
| `--phase <phase>` | 현재 batch에서 특정 phase를 강제 지정. 자동 감지를 override함 | `--phase green` |

### Examples

```bash
# 기본 실행 (자동으로 다음 phase 감지)
/tdd:implement

# base branch 직접 지정
/tdd:implement --base feature/checkout

# 특정 phase 강제 실행 (재시도, 건너뛰기 용)
/tdd:implement --phase green

# 조합 사용
/tdd:implement --base develop --phase refactor
```

## Prerequisites

- **필수**: `.claude/docs/{project-name}/meta.yaml` 존재 (`/tdd:spec` 실행 결과)
- **필수**: Linear TechSpec 문서에 `/tdd:design` 결과물 포함 (Design 섹션)
- **필수**: meta.yaml의 project.id로 Linear에서 "tdd" label issue 조회 가능 (`/tdd:issues`)
- **필수 MCP**: vibe_kanban, Linear plugin

## Execution Flow

### Phase 1: 메타데이터 로드 및 자동 감지

1. **파라미터 파싱**: `--base <branch>`, `--phase <phase>` 파라미터 저장

2. `.claude/docs/{project-name}/implement.yaml` 존재 여부 확인:
   - 파일이 없으면 → 첫 실행: `batch=1, phase=red`
   - 파일이 있으면 → **자동 감지 로직** 실행:

   ```
   current_step 읽기:
     phase=red   & 모든 issues completed → 다음은 green
     phase=green & 모든 issues completed → 다음은 refactor
     phase=refactor & 모든 issues completed →
       다음 batch 있으면 → batch+1, phase=red
       마지막 batch → "done" (모든 구현 완료)
     일부 issues failed → 해당 phase 재시도 제안
   ```

   - `--phase` 파라미터가 있으면 자동 감지 무시하고 지정된 phase 실행
   - `--base` 파라미터가 있으면 implement.yaml의 base_branch override

3. `.claude/docs/{project-name}/meta.yaml`에서 project.id를 추출한다

4. Linear에서 issue를 조회한다:
   ```
   ToolSearch(query: "select:mcp__plugin_linear_linear__list_issues")
   list_issues(project: "{project-id}", labels: ["tdd"])
   ```
   - 응답에서 각 issue의 `id` (Linear API용)와 `url`을 추출하여 저장

5. 조회된 issue 목록을 Blocker/Related로 분류한다

6. 병렬 실행 가능한 issue 배치를 결정한다:

**병렬화 규칙:**
- **Batch 1**: Blocker issues (서로 의존성 없는 Blocker끼리는 병렬 가능)
- **Batch 2**: Related issues (Blocker 완료 후 병렬 실행)

```
Batch 1 (병렬): [Blocker A] [Blocker B] [Blocker C]
  ↓ 완료 대기
Batch 2 (병렬): [Related D] [Related E] [Related F]
```

7. AskUserQuestion으로 실행할 배치와 phase를 확인:
   ```
   question: "다음을 실행합니다. 진행할까요?"

   Batch 1, Phase: Red (테스트 작성 + Draft PR 생성)
   - {issue title} → workspace session
   - {issue title} → workspace session
   ```

### Phase 2: Vibe Kanban 프로젝트, Base Branch, 참여 Repo 설정

> 재실행(implement.yaml 존재) 시 이 Phase는 저장된 값을 사용하여 건너뜀

1. vibe kanban 프로젝트를 확인한다:
   ```
   ToolSearch(query: "select:mcp__vibe_kanban__list_projects")
   ```

2. 프로젝트가 없거나 매칭되지 않으면 AskUserQuestion으로 선택 요청

3. **Base Branch 지정** (우선순위: 파라미터 > implement.yaml > 대화형 입력):

   **3-1. 파라미터 확인 (최우선)**
   - `--base <branch>` 파라미터가 제공되었으면 → 해당 branch 사용

   **3-2. implement.yaml 존재 여부 확인**
   - 파일이 있으면 → `vibe_kanban.base_branch` 읽음 (재실행)

   **3-3. 첫 실행 시 사용자에게 base branch 물어보기**:
   ```
   question: "이 implementation의 base branch를 지정하세요."

   현재 git branch: feature/new-cart
   기본값: feature/new-cart
   또는 다른 branch: [main / develop / feature/new-api / ...]
   ```

4. **참여할 repo 선택**:
   ```
   ToolSearch(query: "select:mcp__vibe_kanban__list_repos")
   → list_repos(project_id: "{project_id}")
   ```

   AskUserQuestion으로 참여 repo 선택:
   ```
   question: "이 feature에 참여할 repo를 선택하세요. (복수 선택 가능)"

   [ ] Frontend (repo-1-id)
   [ ] Backend API (repo-2-id)
   ```

### Phase 3: Issue별 Repo & Package 매핑

Linear issue description의 "작업 대상" 섹션에서 패키지 정보를 추출한다:

1. **Repo 매핑**: Issue 설명의 패키지 경로로 repo 식별
2. **Package 정보 추출**: Linear issue의 "작업 대상" 섹션에서 `package_name`, `package_path`, `target_directory`, `reference_pattern` 추출
3. 정보가 없으면 TechSpec Design 섹션의 "Component & Code" 파일 구조에서 직접 추출
4. 명확하지 않으면 AskUserQuestion으로 확인

### Phase 3.5: 현재 Batch의 Base Branch 결정

현재 batch에 따라 workspace session과 PR의 base branch를 결정한다:

**Batch 1 (첫 배치)**:
- `base_branch` = implement.yaml의 `vibe_kanban.base_branch` (프로젝트 base branch)

**Batch 2+ (이전 배치 존재)**:
1. 이전 batch의 모든 issue가 `phases.refactor.status === "completed"` 확인
2. 이전 batch issue들의 `branch` 필드를 수집
3. 이전 batch에 issue가 **1개**면: 해당 issue의 branch를 base로 사용
4. 이전 batch에 issue가 **여러 개**면: 프로젝트 base branch를 사용 (이전 batch PR들이 이미 merge되었어야 함)
5. ⚠️ 이전 batch PR이 아직 merge되지 않았으면: AskUserQuestion으로 사용자에게 확인
   - "이전 batch PR이 아직 merge되지 않았습니다. 어떤 branch를 base로 사용할까요?"

결정된 base branch를 이후 모든 workspace session과 task description에 사용.

### Phase 4: Task 생성/업데이트 및 Session 시작

현재 batch + phase에 따라 task를 생성(Red) 또는 업데이트(Green/Refactor)하고 workspace session을 시작한다.

**핵심: 각 issue당 하나의 vk task. Red에서 생성하고 Green/Refactor에서 재사용.**

**Phase에 따른 분기:**

#### Red Phase인 경우

각 issue에 대해:

1. **Task 생성** (최초 1회):
   ```
   mcp__vibe_kanban__create_issue(
     project_id: "{project_id}",
     title: "{issue title} [Red]",
     description: "{아래 Red Task Description}"
   )
   ```
   → `issue_id`를 implement.yaml의 `task_id`에 저장

2. **Workspace Session 시작**:
   ```
   mcp__vibe_kanban__start_workspace_session(
     task_id: "{task_id}",
     executor: "CLAUDE_CODE",
     repos: [{ repo_id: "{task의-repo-id}", base_branch: "{base_branch}" }]
   )
   ```

#### Green Phase인 경우

각 issue에 대해 (implement.yaml에서 task_id, branch, pr_number 참조):

1. **기존 Task 업데이트**:
   ```
   mcp__vibe_kanban__update_issue(
     issue_id: "{task_id}",
     title: "{issue title} [Green]",
     description: "{아래 Green Task Description}"
   )
   ```

2. **Workspace Session 시작** (같은 task에서 새 session):
   ```
   mcp__vibe_kanban__start_workspace_session(
     task_id: "{task_id}",
     executor: "CLAUDE_CODE",
     repos: [{ repo_id: "{task의-repo-id}", base_branch: "{issue.branch}" }]
   )
   ```
   > Note: `base_branch`에 Red에서 생성한 **issue branch**를 사용하여 이어서 작업

#### Refactor Phase인 경우

각 issue에 대해 (implement.yaml에서 task_id, branch, pr_number 참조):

1. **기존 Task 업데이트**:
   ```
   mcp__vibe_kanban__update_issue(
     issue_id: "{task_id}",
     title: "{issue title} [Refactor]",
     description: "{아래 Refactor Task Description}"
   )
   ```

2. **Workspace Session 시작** (같은 task에서 새 session):
   ```
   mcp__vibe_kanban__start_workspace_session(
     task_id: "{task_id}",
     executor: "CLAUDE_CODE",
     repos: [{ repo_id: "{task의-repo-id}", base_branch: "{issue.branch}" }]
   )
   ```

---

## Phase별 Task Description 템플릿

### Red Task Description

````
🚫 **금지 사항 — 아래 규칙을 반드시 준수하세요:**
- `Skill` 도구를 호출하지 마세요 (어떤 스킬이든 — `/tdd:start`, `/plan`, `/commit` 등 모두 금지)
- `EnterPlanMode` 도구를 호출하지 마세요
- PR 생성 시 `--base` 플래그를 반드시 아래 Context의 **Base Branch** 값으로 지정하세요. `main`을 base로 사용하지 마세요.
- 이 workspace는 자동 실행 환경입니다. 아래 "작업 순서"를 1번부터 순서대로 즉시 실행하세요.

## Phase: RED - 실패하는 테스트 작성

이 워크스페이스의 목표는 **테스트만** 작성하고 **Draft PR을 생성**하는 것입니다.
구현 코드를 작성하지 마세요.

## Context

- Linear Issue: {linear_issue_url}
- TechSpec Document: {meta.yaml의 document.url}
- **Base Branch**: `{base_branch}`
- **작업 대상 패키지**: `{package_name}` (`{package_path}`)
- **작업 디렉토리**: `{package_path}/{target_directory}`
- **기존 패턴 참조**: `{package_path}/{reference_pattern}` (같은 패키지 내 유사 모듈)

## 관련 테스트 케이스

{Linear TechSpec 문서에서 해당 issue의 Given/When/Then 테이블}

## 관련 설계

{Linear TechSpec 문서의 Design 섹션에서 해당 데이터 모델(Interface)/Usecase/Component 정보}

## 작업 순서

1. `{base_branch}`에서 `{branch_name}` 브랜치 생성
2. Given/When/Then 테스트 케이스를 실제 테스트 코드로 변환
   - ⚠️ `describe`/`it`/`test` 설명은 **한국어**로 작성
   - ⚠️ TC#, TC1 등 번호 접두사를 붙이지 않음 — 설명만 작성
   - ⚠️ UI 렌더링 자체를 검증하는 테스트는 지양. **사용자 행동**(클릭, 입력 등)과 그 **결과**(핸들러 호출, 상태 변경, 다른 컴포넌트 노출)를 검증하는 통합 테스트 위주로 작성
   - ❌ `it('RecommendCreateAd를 렌더링한다')` → ✅ `it('광고가 없을 때 클릭하면 onCreateAd가 호출된다')`
   - 예: `describe('PostAdListItem')`, `it('광고가 0개일 때 광고 생성 유도 영역을 클릭하면 onCreateAd가 호출된다')`
3. 테스트 실행 → **실패 확인** (Red 상태)
4. 커밋 & 푸시
5. Draft PR 생성:
   ```bash
   gh pr create --draft --base {base_branch} \
     --title "[Red] {issue title}" \
     --body "$(cat <<'EOF'
   ## 🔴 Red Phase - 실패하는 테스트

   이 PR은 TDD Red phase의 결과물입니다.
   실패하는 테스트 코드만 포함되어 있습니다.

   ### 리뷰 포인트
   - [ ] 테스트 케이스가 요구사항을 정확히 반영하는가?
   - [ ] Given/When/Then 구조가 명확한가?
   - [ ] 테스트 범위가 충분한가?

   > 리뷰 완료 후 Green phase에서 구현이 진행됩니다.
   EOF
   )"
   ```

   ⚠️ **중요**: `--base {base_branch}` 플래그 필수! `main`을 base로 사용하면 안 됩니다!

## 완료 조건

- [ ] 테스트 파일이 존재함
- [ ] 테스트 실행 시 실패함 (구현이 없으므로)
- [ ] `{branch_name}` 브랜치에 push됨
- [ ] Draft PR 생성됨

## Linear 동기화 (필수)

**Linear Issue ID**: `{issue_id}`

### 작업 시작 시
```
ToolSearch(query: "select:mcp__plugin_linear_linear__update_issue")
update_issue(id: "{issue_id}", state: "started")
```

### PR 생성 후
```
ToolSearch(query: "select:mcp__plugin_linear_linear__create_comment")
create_comment(issueId: "{issue_id}", body: "🔴 Red Phase 완료 - Draft PR: {pr_url}")
```
````

### Green Task Description

````
🚫 **금지 사항 — 아래 규칙을 반드시 준수하세요:**
- `Skill` 도구를 호출하지 마세요 (어떤 스킬이든 — `/tdd:start`, `/plan`, `/commit` 등 모두 금지)
- `EnterPlanMode` 도구를 호출하지 마세요
- 이 workspace는 자동 실행 환경입니다. 아래 "작업 순서"를 1번부터 순서대로 즉시 실행하세요.

## Phase: GREEN - 테스트 통과시키기

이 워크스페이스의 목표는 기존 테스트를 통과시키는 **최소한의 코드**를 작성하는 것입니다.
과도한 추상화나 리팩토링을 하지 마세요.

## Context

- Linear Issue: {linear_issue_url}
- TechSpec Document: {meta.yaml의 document.url}
- **Branch**: `{branch_name}` (Red 단계에서 생성됨)
- **PR**: {pr_url} (이미 존재하는 Draft PR)
- **작업 대상 패키지**: `{package_name}` (`{package_path}`)
- **작업 디렉토리**: `{package_path}/{target_directory}`
- **기존 패턴 참조**: `{package_path}/{reference_pattern}` (같은 패키지 내 유사 모듈)

## 관련 설계

{Linear TechSpec 문서의 Design 섹션에서 해당 데이터 모델(Interface)/Usecase/Component 정보}

## 작업 순서

1. `{branch_name}` 브랜치 checkout
2. 기존 테스트 코드 확인
3. 테스트를 통과시키는 **최소한의** 코드 작성
4. 테스트 실행 → **성공 확인** (Green 상태)
5. 커밋 & 푸시 (같은 branch → PR 자동 업데이트)
6. PR title 업데이트:
   ```bash
   gh pr edit {pr_number} --title "[Green] {issue title}"
   ```
7. PR에 코멘트:
   ```bash
   gh pr comment {pr_number} --body "$(cat <<'EOF'
   ## 🟢 Green Phase 완료

   모든 테스트가 통과합니다. 최소한의 구현만 포함되어 있습니다.

   ### 리뷰 포인트
   - [ ] 구현이 테스트 요구사항을 올바르게 충족하는가?
   - [ ] 불필요한 코드가 포함되지 않았는가?
   - [ ] 로직이 합리적인가?

   > 리뷰 완료 후 Refactor phase에서 코드 품질이 개선됩니다.
   EOF
   )"
   ```

## 완료 조건

- [ ] 모든 테스트 통과
- [ ] 최소한의 구현만 포함 (no gold plating)
- [ ] `{branch_name}` 브랜치에 push됨 (PR 자동 업데이트)

## Linear 동기화 (필수)

**Linear Issue ID**: `{issue_id}`

```
ToolSearch(query: "select:mcp__plugin_linear_linear__create_comment")
create_comment(issueId: "{issue_id}", body: "🟢 Green Phase 완료 - PR: {pr_url}")
```
````

### Refactor Task Description

````
🚫 **금지 사항 — 아래 규칙을 반드시 준수하세요:**
- `Skill` 도구를 호출하지 마세요 (어떤 스킬이든 — `/tdd:start`, `/plan`, `/commit` 등 모두 금지)
- `EnterPlanMode` 도구를 호출하지 마세요
- 이 workspace는 자동 실행 환경입니다. 아래 "작업 순서"를 1번부터 순서대로 즉시 실행하세요.

## Phase: REFACTOR - 리팩토링

이 워크스페이스의 목표는 코드 품질을 개선하는 것입니다.

## Context

- Linear Issue: {linear_issue_url}
- TechSpec Document: {meta.yaml의 document.url}
- **Branch**: `{branch_name}`
- **PR**: {pr_url} (이미 존재하는 Draft PR)
- **작업 대상 패키지**: `{package_name}` (`{package_path}`)
- **작업 디렉토리**: `{package_path}/{target_directory}`
- **기존 패턴 참조**: `{package_path}/{reference_pattern}` (같은 패키지 내 유사 모듈)

## 관련 설계

{Linear TechSpec 문서의 Design 섹션에서 해당 데이터 모델(Interface)/Usecase/Component 정보}

## 작업 순서

1. `{branch_name}` 브랜치 checkout
2. 코드 품질 개선 (중복 제거, 네이밍, 구조 개선)
3. Business Rules에 해당하는 반복 로직은 `entity-object-pattern` 스킬을 참조하여 Entity Object로 그룹화
4. 테스트 실행 → **여전히 성공** 확인
5. Pre-commit 체크:
   ```bash
   # 1. Type check
   npx tsc --noEmit

   # 2. Biome check
   npx biome check .

   # 3. Test
   npx vitest run
   ```
   실패 시 수정 후 재실행. 모두 통과해야 commit 가능.
6. 커밋 & 푸시 (같은 branch → PR 자동 업데이트)
7. PR title 업데이트 (phase prefix 제거):
   ```bash
   gh pr edit {pr_number} --title "{issue title}"
   ```
8. PR에 코멘트:
   ```bash
   gh pr comment {pr_number} --body "$(cat <<'EOF'
   ## 🔵 Refactor Phase 완료

   코드 품질이 개선되었습니다. 모든 테스트와 lint가 통과합니다.

   ### 리뷰 포인트
   - [ ] 코드 구조와 네이밍이 적절한가?
   - [ ] 중복이 제거되었는가?
   - [ ] 전체적인 코드 품질이 만족스러운가?

   > 리뷰 승인 후 `gh pr ready`로 PR을 open하세요.
   EOF
   )"
   ```

## 완료 조건

- [ ] 모든 테스트 통과
- [ ] tsc, biome 통과
- [ ] `{branch_name}` 브랜치에 push됨 (PR 자동 업데이트)

## Linear 동기화 (필수)

**Linear Issue ID**: `{issue_id}`

```
ToolSearch(query: "select:mcp__plugin_linear_linear__update_issue")
# "In Review" 상태 ID 확인: list_issue_statuses(team: "{your-team}")에서
# "In Review" name을 가진 상태의 id 사용
update_issue(id: "{issue_id}", stateId: "{in-review-state-id}")

ToolSearch(query: "select:mcp__plugin_linear_linear__create_comment")
create_comment(issueId: "{issue_id}", body: "🔵 Refactor 완료 - 최종 리뷰: {pr_url}")
```

> Note: "Done" 상태는 PR이 merge된 후 별도로 처리됩니다.
````

---

### Phase 6: 실행 상태 저장

`.claude/docs/{project-name}/implement.yaml`에 실행 상태를 저장한다:

```yaml
# .claude/docs/{project-name}/implement.yaml
project:
  id: "{project-id}"
  name: "{project-name}"
document:
  url: "{linear-document-url}"  # meta.yaml에서 참조
vibe_kanban:
  project_id: "{vibe-project-id}"
  base_branch: "{selected_base_branch}"  # Phase 2에서 선택한 base branch
  repos:
    - id: "{frontend-repo-id}"
      name: "frontend"
      base_branch: "{selected_base_branch}"
    - id: "{backend-repo-id}"
      name: "backend"
      base_branch: "{selected_base_branch}"
current_step:                    # 현재 진행 위치 (자동 감지에 사용)
  batch: 1
  phase: "red"                   # "red" | "green" | "refactor" | "done"
batches:
  - batch: 1
    type: blocker
    issues:
      - issue_id: "{linear-issue-id}"
        issue_url: "{linear-issue-url}"
        repo_id: "{frontend-repo-id}"
        title: "{title}"
        package_name: "{package-name}"          # Phase 3에서 추출
        package_path: "{package-path}"          # Phase 3에서 추출
        target_directory: "{target-dir}"        # Phase 3에서 추출
        reference_pattern: "{ref-path}"         # Phase 3에서 추출
        task_id: "{vibe-task-id}"  # Red에서 생성, 전 phase에서 재사용
        branch: "{issue-branch}"   # Red에서 생성, Green/Refactor에서 재사용
        pr_url: "{github-pr-url}"  # Red에서 생성, 이후 자동 업데이트
        pr_number: 42
        phases:
          red:
            status: "completed"    # "todo" | "inprogress" | "completed" | "failed"
          green:
            status: "inprogress"
          refactor:
            status: "todo"
  - batch: 2
    type: related
    issues:
      - issue_id: "{linear-issue-id}"
        issue_url: "{linear-issue-url}"
        repo_id: "{backend-repo-id}"
        title: "{title}"
        package_name: "{package-name}"
        package_path: "{package-path}"
        target_directory: "{target-dir}"
        reference_pattern: "{ref-path}"
        task_id: null              # Red phase에서 생성됨
        branch: null               # Red phase 전이므로 아직 없음
        pr_url: null
        pr_number: null
        phases:
          red:
            status: "todo"
          green:
            status: "todo"
          refactor:
            status: "todo"
created_at: "{ISO-8601}"
```

**상태 저장 시점별 업데이트:**

- **Red 완료 후**: `current_step.phase` → `"green"`, `issues[].task_id` 기록, `issues[].branch` 기록, `issues[].pr_url`/`pr_number` 기록, `phases.red.status` → `"completed"`
- **Green 완료 후**: `current_step.phase` → `"refactor"`, `phases.green.status` → `"completed"` (task_id 변경 없음)
- **Refactor 완료 후**: 다음 batch 있으면 `current_step` → `{batch+1, phase: "red"}`, 없으면 `phase` → `"done"` (task_id 변경 없음)

### Phase 7: 결과 보고

Phase별로 다른 결과 보고:

#### Red 완료 시

```
Batch 1, Phase: Red 완료 🔴

Project: {Project Name}
TechSpec: {document URL}

Draft PR 생성됨:
- [Frontend] Cart UI Component → PR #{pr_number} (Draft)
- [Backend] Cart Interface → PR #{pr_number} (Draft)
- [Backend] API Endpoint → PR #{pr_number} (Draft)

다음 단계:
1. 각 Draft PR에서 테스트 코드를 리뷰하세요
2. 리뷰 완료 후 /tdd:implement 를 실행하면 Green phase가 시작됩니다
   (또는 /tdd:implement --phase green)
```

#### Green 완료 시

```
Batch 1, Phase: Green 완료 🟢

PR 업데이트됨:
- [Frontend] Cart UI Component → PR #{pr_number} (구현 추가)
- [Backend] Cart Interface → PR #{pr_number} (구현 추가)
- [Backend] API Endpoint → PR #{pr_number} (구현 추가)

다음 단계:
1. 각 PR에서 구현 코드를 리뷰하세요
2. 리뷰 완료 후 /tdd:implement 를 실행하면 Refactor phase가 시작됩니다
   (또는 /tdd:implement --phase refactor)
```

#### Refactor 완료 시

```
Batch 1, Phase: Refactor 완료 🔵

PR 최종 업데이트:
- [Frontend] Cart UI Component → PR #{pr_number}
- [Backend] Cart Interface → PR #{pr_number}
- [Backend] API Endpoint → PR #{pr_number}

다음 단계:
1. 각 PR에서 최종 코드를 리뷰하세요
2. 승인되면 PR을 Ready for Review로 전환하세요:
   gh pr ready {pr_number_1} && gh pr ready {pr_number_2} && gh pr ready {pr_number_3}
3. Batch 2가 있으면 /tdd:implement 로 계속 진행합니다
```

### Phase 8: (Human) Review

사용자가 각 PR의 diff를 리뷰한다.
- Red: 테스트 코드의 정확성과 범위 확인
- Green: 구현의 합리성과 최소성 확인
- Refactor: 코드 품질과 구조 확인, 승인 시 `gh pr ready`로 PR open

## Error Handling

| 상황 | 대응 |
|------|------|
| meta.yaml 없음 | `/tdd:spec`을 먼저 실행하라고 안내 |
| Linear issue 조회 실패 | `/tdd:issues`를 먼저 실행하라고 안내 |
| "tdd" label issue 없음 | `/tdd:issues`를 먼저 실행하라고 안내 |
| Vibe Kanban 프로젝트 없음 | AskUserQuestion으로 프로젝트 선택 또는 생성 안내 |
| Repo 정보 없음 | AskUserQuestion으로 repo 선택 요청 |
| Session 시작 실패 | 에러 로그 출력, 수동 재시도 안내 |
| 이전 phase가 failed | 재시도 여부 AskUserQuestion으로 확인 |
| PR이 닫혀있음 | 에러 로그 + PR 재생성 안내 |
| 모든 구현 완료 (done) | "모든 배치가 완료되었습니다" 안내 |

## Example: 첫 실행 → Red Phase

```
사용자: /tdd:implement

Claude: .claude/docs/my-feature/meta.yaml 에서 project.id를 로드합니다...
Claude: implement.yaml이 없습니다. 첫 실행입니다.
Claude: Linear에서 "tdd" label issue를 조회합니다...
  → Linear issues (3 blockers, 2 related)

Claude: [AskUserQuestion] 이 implementation의 base branch를 지정하세요.
  현재 git branch: feature/new-cart
  추천: feature/new-cart

사용자: feature/new-cart

Claude: [AskUserQuestion] 이 feature에 참여할 repo를 선택하세요.

사용자: Frontend, Backend API

Claude: [AskUserQuestion] 다음을 실행합니다:

  Batch 1, Phase: Red (테스트 작성 + Draft PR 생성)
  - [Backend] Cart Interface 및 상수 정의
  - [Frontend] Cart UI Component
  - [Backend] Cart API 엔드포인트

사용자: 진행

Claude: Vibe Kanban에 task 생성 중... (3개 tasks)
Claude: Workspace session 시작 중...

Claude:
  Batch 1, Phase: Red 시작 🔴

  Project: my-feature
  TechSpec: https://linear.app/daangn/document/fe-techspec-xxx
  Repos: Frontend, Backend API
  Base Branch: feature/new-cart

  워크스페이스:
  - [Backend] Cart Interface 및 상수 정의 [Red] → task 생성 + session 시작됨
  - [Frontend] Cart UI Component [Red] → task 생성 + session 시작됨
  - [Backend] Cart API 엔드포인트 [Red] → task 생성 + session 시작됨

  다음 단계:
  1. Conductor에서 각 워크스페이스 진행 상황을 모니터링하세요
  2. 각 Draft PR에서 테스트 코드를 리뷰하세요
  3. 리뷰 완료 후 /tdd:implement 를 실행하면 Green phase가 시작됩니다
```

## Example: Red 완료 후 → Green Phase (자동 감지)

```
사용자: /tdd:implement

Claude: .claude/docs/my-feature/implement.yaml 을 발견했습니다.
Claude: current_step: batch=1, phase=red (completed)
Claude: 자동 감지: 다음은 Batch 1, Phase: Green

Claude: [AskUserQuestion] 다음을 실행합니다:

  Batch 1, Phase: Green (구현 → 같은 PR에 push)
  - [Backend] Cart Interface 및 상수 정의 → PR #42
  - [Frontend] Cart UI Component → PR #43
  - [Backend] Cart API 엔드포인트 → PR #44

사용자: 진행

Claude: 기존 task 업데이트 중... (3개 tasks → [Green])
Claude: Workspace session 시작 중... (각 issue branch에서 이어서 작업)

Claude:
  Batch 1, Phase: Green 시작 🟢
  ...
```

## Example: Refactor 완료 → Batch 전환

```
사용자: /tdd:implement

Claude: .claude/docs/my-feature/implement.yaml 을 발견했습니다.
Claude: current_step: batch=1, phase=refactor (completed)
Claude: 자동 감지: 다음은 Batch 2, Phase: Red

Claude: [AskUserQuestion] Batch 1 완료! PR을 Ready for Review로 전환하시겠습니까?
  - PR #42: Cart Interface 및 상수 정의
  - PR #43: Cart UI Component
  - PR #44: Cart API 엔드포인트

  그리고 Batch 2를 시작합니다:

  Batch 2, Phase: Red (테스트 작성 + Draft PR 생성)
  - [Frontend] Wishlist 저장 기능
  - [Backend] Cart 미니 뷰

사용자: PR open하고 Batch 2 진행

Claude: PR을 Ready for Review로 전환합니다...
  gh pr ready 42 && gh pr ready 43 && gh pr ready 44

Claude: Vibe Kanban에 task 생성 중... (2개 tasks)
...
```

## Example: --phase 파라미터로 강제 실행

```
사용자: /tdd:implement --phase green

Claude: .claude/docs/my-feature/implement.yaml 을 발견했습니다.
Claude: --phase 파라미터 감지: green (자동 감지 무시)
Claude: Batch 1, Phase: Green 강제 실행

...
```

## 참고

- **단일 Task 모델**: 각 issue당 하나의 vk task를 생성 (Red). Green/Refactor에서는 `update_issue`로 같은 task를 재사용
- implement.yaml의 `current_step`으로 다음 실행할 (batch, phase)를 자동 감지
- `/tdd:implement`를 반복 실행하면 Red → Green → Refactor → 다음 Batch Red → ... 순서로 진행
- `--phase` 파라미터로 자동 감지를 무시하고 특정 phase 강제 실행 가능
- `--base` 파라미터로 implement.yaml의 base_branch를 override 가능
- 하나의 PR이 3개 phase를 관통: Red에서 Draft PR 생성, Green/Refactor에서 같은 branch에 push하여 자동 업데이트
- PR title이 phase별로 업데이트됨: `[Red] title` → `[Green] title` → `title`
