---
name: tdd/implement
description: spec/design/issues 기반으로 병렬 워크스페이스를 생성하여 Red-Green-Refactor 방식으로 구현
allowed-tools:
  - Read
  - Write
  - Glob
  - Bash
  - ToolSearch
  - AskUserQuestion
---

# TDD Implement Command

`/tdd:spec`, `/tdd:design`, `/tdd:issues`의 결과물을 기반으로 병렬 구현을 시작한다. 각 워크스페이스는 Red-Green-Refactor TDD 사이클을 따른다.

## Prerequisites

- **필수**: `.claude/docs/{project-name}/meta.yaml` 존재 (`/tdd:spec` 실행 결과)
- **필수**: Linear TechSpec 문서에 `/tdd:design` 결과물 포함 (Design 섹션)
- **필수**: meta.yaml의 project.id로 Linear에서 "tdd" label issue 조회 가능 (`/tdd:issues`)
- **필수 MCP**: vibe_kanban, Linear plugin

## Execution Flow

### Phase 1: 메타데이터 로드 및 Linear Issue 조회

1. `.claude/docs/{project-name}/meta.yaml`에서 project.id를 추출한다
2. Linear에서 issue를 조회한다:
   ```
   ToolSearch(query: "select:mcp__plugin_linear_linear__list_issues")
   list_issues(project: "{project-id}", labels: ["tdd"])
   ```
3. 조회된 issue 목록을 Blocker/Related로 분류한다
4. 병렬 실행 가능한 issue 배치를 결정한다:

**병렬화 규칙:**
- **Batch 1**: Blocker issues (서로 의존성 없는 Blocker끼리는 병렬 가능)
- **Batch 2**: Related issues (Blocker 완료 후 병렬 실행)

```
Batch 1 (병렬): [Blocker A] [Blocker B] [Blocker C]
  ↓ 완료 대기
Batch 2 (병렬): [Related D] [Related E] [Related F]
```

5. AskUserQuestion으로 실행할 배치를 확인:
   ```
   question: "다음 배치를 병렬로 실행합니다. 진행할까요?"

   Batch 1 (Blocker - 먼저 실행):
   - {issue title} → workspace session
   - {issue title} → workspace session

   Batch 2 (Related - Batch 1 완료 후):
   - {issue title} → workspace session
   ```

### Phase 2: Vibe Kanban 프로젝트 및 참여 Repo 설정

1. vibe kanban 프로젝트를 확인한다:
   ```
   ToolSearch(query: "select:mcp__vibe_kanban__list_projects")
   ```

2. 프로젝트가 없거나 매칭되지 않으면 AskUserQuestion으로 선택 요청

3. **참여할 repo 선택** (중요: 한 feature가 여러 repo에 걸칠 수 있음):
   ```
   ToolSearch(query: "select:mcp__vibe_kanban__list_repos")
   → list_repos(project_id: "{project_id}")
   ```

   AskUserQuestion으로 참여 repo 선택:
   ```
   question: "이 feature에 참여할 repo를 선택하세요. (복수 선택 가능)"

   [ ] Frontend (repo-1-id)
   [ ] Backend API (repo-2-id)
   [ ] Mobile (repo-3-id)

   예: Frontend, Backend API
   ```

   선택된 repo들을 메모: `repos = ["{repo-1-id}", "{repo-2-id}"]`

### Phase 3: Issue별 Repo 매핑

Linear 문서의 Design 섹션 또는 issue 제목/설명에서 어느 repo에 해당하는 작업인지 파악:

- "Cart Entity" → Frontend 또는 Backend?
- Issue 설명 또는 Design 섹션의 Component/Server 부분 참조
- 명확하지 않으면 AskUserQuestion으로 확인

매핑 예:
```
Blocker A: Cart Entity 정의 → Backend
Blocker B: Cart UI Component → Frontend
Blocker C: API 엔드포인트 → Backend
```

### Phase 4: Task 생성 및 Session 시작

현재 배치의 각 issue에 대해:

1. **Vibe Kanban Task 생성**:
   ```
   mcp__vibe_kanban__create_task(
     project_id: "{project_id}",
     title: "{issue title}",
     description: "{issue 상세 + 아래 TDD 지시사항}"
   )
   ```

2. **Task description에 포함할 TDD 지시사항:**

   ````
   ## Context

   - Linear Issue: {linear_issue_url}
   - TechSpec Document: {meta.yaml의 document.url}

   ## 관련 테스트 케이스

   {Linear TechSpec 문서에서 해당 issue의 Given/When/Then 테이블}

   ## 관련 설계

   {Linear TechSpec 문서의 Design 섹션에서 해당 Entity/Usecase/Component 정보}

   ## TDD Workflow (Red-Green-Refactor)

   ### 1. Red - 실패하는 테스트 작성
   - Given/When/Then 테스트 케이스를 실제 테스트 코드로 변환
   - 테스트 실행 → 실패 확인

   ### 2. Green - 최소 구현
   - 테스트를 통과시키는 최소한의 코드 작성
   - 테스트 실행 → 성공 확인

   ### 3. Refactor - 리팩토링
   - 코드 품질 개선 (중복 제거, 네이밍 등)
   - 테스트 실행 → 여전히 성공 확인

   ## Commit 전 필수 체크

   반드시 아래 3가지를 모두 통과한 후 commit:
   ```bash
   # 1. Type check
   npx tsc --noEmit

   # 2. Biome check
   npx biome check .

   # 3. Test
   npx vitest run
   ```

   실패 시 수정 후 재실행. 모두 통과해야 commit 가능.

   ## Commit & PR

   1. 변경사항 commit (conventional commit format)
   2. Draft PR 생성: `gh pr create --draft --title "{issue title}" --body "..."`
   3. Linear issue에 PR URL 코멘트 추가
   ````

3. **Workspace Session 시작**:
   ```
   # Phase 3에서 매핑한 repo_id 사용
   mcp__vibe_kanban__start_workspace_session(
     task_id: "{task_id}",
     executor: "CLAUDE_CODE",
     repos: [{ repo_id: "{task의-repo-id}", base_branch: "main" }]
   )
   ```

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
  repos:                          # Phase 2에서 선택한 repo 목록
    - id: "{frontend-repo-id}"
      name: "frontend"
      base_branch: "main"
    - id: "{backend-repo-id}"
      name: "backend"
      base_branch: "main"
batches:
  - batch: 1
    type: blocker
    tasks:
      - task_id: "{vibe-task-id}"
        repo_id: "{frontend-repo-id}"  # Phase 3에서 매핑한 repo
        issue_url: "{linear-issue-url}"
        title: "{title}"
        status: "inprogress"
      - task_id: "{vibe-task-id}"
        repo_id: "{backend-repo-id}"   # 다른 repo일 수 있음
        issue_url: "{linear-issue-url}"
        title: "{title}"
        status: "inprogress"
  - batch: 2
    type: related
    tasks:
      - task_id: "{vibe-task-id}"
        repo_id: "{frontend-repo-id}"
        issue_url: "{linear-issue-url}"
        title: "{title}"
        status: "todo"
created_at: "{ISO-8601}"
```

### Phase 7: 결과 보고

```
Implementation 시작!

Project: {Project Name}
TechSpec: {document URL}
Vibe Kanban: {project_id}
Repos: Frontend (repo-1), Backend (repo-2)

Batch 1 (Blocker) - 병렬 실행 중:
- [Frontend] {task title} → workspace session 시작됨
- [Backend] {task title} → workspace session 시작됨
- [Frontend] {task title} → workspace session 시작됨

Batch 2 (Related) - 대기 중:
- [Frontend] {task title}
- [Backend] {task title}

Status: .claude/docs/{project-name}/implement.yaml

각 워크스페이스는 Red-Green-Refactor로 진행됩니다.
Commit 전 type check + biome check + test 통과 필수.
완료되면 Draft PR이 생성됩니다.

다음 단계:
1. Conductor에서 각 워크스페이스 진행 상황을 모니터링하세요
2. Draft PR을 리뷰하세요 (각 PR은 해당 repo에 생성됨)
3. Batch 1 완료 후 Batch 2를 시작하려면 /tdd:implement를 다시 실행하세요
```

### Phase 8: (Human) Review

사용자가 각 워크스페이스의 Draft PR을 검수하고 리뷰한다.

## Error Handling

| 상황 | 대응 |
|------|------|
| meta.yaml 없음 | `/tdd:spec`을 먼저 실행하라고 안내 |
| Linear issue 조회 실패 | `/tdd:issues`를 먼저 실행하라고 안내 |
| "tdd" label issue 없음 | `/tdd:issues`를 먼저 실행하라고 안내 |
| Vibe Kanban 프로젝트 없음 | AskUserQuestion으로 프로젝트 선택 또는 생성 안내 |
| Repo 정보 없음 | AskUserQuestion으로 repo 선택 요청 |
| Session 시작 실패 | 에러 로그 출력, 수동 재시도 안내 |

## Example: 단일 Repo

```
사용자: /tdd:implement

Claude: .claude/docs/my-feature/meta.yaml 에서 project.id를 로드합니다...
Claude: Linear에서 "tdd" label issue를 조회합니다...
  → Linear issues (3 blockers, 2 related)

Claude: [AskUserQuestion] 이 feature에 참여할 repo를 선택하세요.

사용자: Frontend

Claude: [AskUserQuestion] 다음 배치를 병렬로 실행합니다:

  Batch 1 (Blocker - 병렬):
  - Cart Entity 및 Type 정의
  - Cart API 인터페이스 설계
  - 공통 컴포넌트 (QuantitySelector, Button)

사용자: 진행

Claude: Vibe Kanban에 task 생성 중...
Claude: Workspace session 시작 중...

Claude: Implementation 시작!
  Project: my-feature
  TechSpec: https://linear.app/daangn/document/fe-techspec-xxx
  Repos: Frontend
  Batch 1: 3개 workspace session 실행 중
  Batch 2: 2개 대기 중
```

## Example: 다중 Repo (Frontend + Backend)

```
사용자: /tdd:implement

Claude: .claude/docs/my-feature/meta.yaml 에서 project.id를 로드합니다...
Claude: Linear에서 "tdd" label issue를 조회합니다...
  → Linear issues (4 blockers, 3 related)

Claude: [AskUserQuestion] 이 feature에 참여할 repo를 선택하세요.

사용자: Frontend, Backend API

Claude: Issue별 repo 매핑:
  - Cart Entity 및 Type 정의 → Backend API
  - Cart UI Component → Frontend
  - Cart API 엔드포인트 → Backend API
  - 공통 로직 (validation) → Backend API

Claude: [AskUserQuestion] 다음 배치를 병렬로 실행합니다:

  Batch 1 (Blocker - 병렬):
  - [Backend] Cart Entity 및 Type 정의
  - [Frontend] Cart UI Component
  - [Backend] Cart API 엔드포인트

사용자: 진행

Claude: Vibe Kanban에 task 생성 중...
Claude: Workspace session 시작 중...

Claude: Implementation 시작!
  Project: my-feature
  TechSpec: https://linear.app/daangn/document/fe-techspec-xxx
  Repos: Frontend, Backend API
  Batch 1: 3개 workspace session 실행 중 (Frontend 1개, Backend 2개)
  Batch 2: 3개 대기 중

각 workspace는 해당 repo에서 작업하며, Draft PR이 각 repo에 생성됩니다.
```
