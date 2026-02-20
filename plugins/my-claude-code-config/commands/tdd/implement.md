---
name: tdd/implement
description: spec/design/issues 기반으로 단일 Task에 Red→Green→Refactor 전체 워크플로우를 포함하여 생성. Workspace가 자체적으로 phase를 순차 실행하며, 각 phase 사이에 인간 리뷰를 거침
allowed-tools:
  - Read
  - Write
  - Glob
  - Bash
  - ToolSearch
  - AskUserQuestion
  - Skill
---

# TDD Implement Command

`/tdd:spec`, `/tdd:design`, `/tdd:issues`의 결과물을 기반으로 구현을 시작한다.

**핵심 원칙: 단일 Task 생성 후 Workspace가 자율 실행, Phase 사이 Human Review**

각 issue당 하나의 vk task를 생성한다. Task description에 Red→Green→Refactor 전체 워크플로우와 Review Gate를 포함한다. Workspace agent가 이를 순차적으로 실행하며, 각 phase 완료 시 AskUserQuestion으로 인간 리뷰를 받는다.

```
Workspace 내부 흐름:
Red      → 테스트 작성 & commit                        → 🔍 Review Gate 1: 인간 리뷰
Green    → 구현 코드 commit                           → 🔍 Review Gate 2: 인간 리뷰
Visual   → Figma 비교 & Storybook/Preview (조건부)      → 🔍 Review Gate 2.5: 인간 리뷰
Refactor → 리팩토링 commit & push → Draft PR 생성 → Linear 동기화 → 🔍 Review Gate 3: 최종 리뷰
최종 승인 → Draft PR → Ready for Review (open)
```

implement command는 task를 생성하고 session을 시작하는 역할만 한다.
재실행 시에는 vk issue 상태를 확인하여 다음 batch 진행 여부를 결정한다.

## Usage

```
/tdd:implement [--base <branch>]
```

### Parameters

| Parameter | Description | Example |
|-----------|-------------|---------|
| `--base <branch>` | PR의 target branch를 직접 지정. implement.yaml 설정을 override함 | `--base feature/new-cart` |

### Examples

```bash
# 기본 실행 (첫 실행이면 Batch 1 task 생성, 재실행이면 상태 확인)
/tdd:implement

# base branch 직접 지정
/tdd:implement --base feature/checkout
```

## Prerequisites

- **필수**: `.claude/docs/{project-name}/meta.yaml` 존재 (`/tdd:spec` 실행 결과)
- **필수**: Linear TechSpec 문서에 `/tdd:design` 결과물 포함 (Design 섹션)
- **필수**: meta.yaml의 project.id로 Linear에서 "tdd" label issue 조회 가능 (`/tdd:issues`)
- **필수 MCP**: vibe_kanban, Linear plugin

## Execution Flow

### Phase 1: 메타데이터 로드 및 상태 확인

1. **파라미터 파싱**: `--base <branch>` 파라미터 저장

2. `.claude/docs/{project-name}/implement.yaml` 존재 여부 확인:
   - 파일이 없으면 → 첫 실행: Phase 2로 진행
   - 파일이 있으면 → **vk issue 상태 조회**:

   ```
   현재 batch의 모든 task_id에 대해:
     ToolSearch(query: "select:mcp__vibe_kanban__get_issue")
     get_issue(issue_id: "{task_id}")
     → status 확인

   모든 task completed → 다음 batch 있으면 batch+1로 진행, 없으면 "done"
   일부 task 미완료 → 진행 상황 보고:
     - 각 task의 현재 상태 표시
     - "진행 중인 워크스페이스를 완료시켜주세요" 안내
   ```

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

7. AskUserQuestion으로 실행할 배치를 확인:
   ```
   question: "다음을 실행합니다. 진행할까요?"

   Batch 1 (Red→Green→Refactor, 각 phase 후 리뷰)
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
1. 이전 batch의 task_id들로 vk issue를 조회하여 관련 PR 정보 파악
2. 또는 `gh pr list` 등으로 GitHub에서 직접 branch 정보 조회
3. 이전 batch에 issue가 **1개**면: 해당 issue의 branch를 base로 사용
4. 이전 batch에 issue가 **여러 개**면: 프로젝트 base branch를 사용 (이전 batch PR들이 이미 merge되었어야 함)
5. ⚠️ 판단이 어려우면: AskUserQuestion으로 사용자에게 base branch 확인

결정된 base branch를 이후 모든 workspace session과 task description에 사용.

### Phase 4: Task 생성 및 Session 시작

현재 batch의 각 issue에 대해 vk task를 생성하고 workspace session을 시작한다.

**핵심: task를 한번 생성하면 update하지 않는다. Workspace agent가 Red→Green→Refactor를 자체 처리.**

각 issue에 대해:

1. **Task 생성** (배치당 1회):
   ```
   mcp__vibe_kanban__create_issue(
     project_id: "{project_id}",
     title: "{issue title}",
     description: "{아래 통합 Task Description}"
   )
   ```
   → `task_id`를 implement.yaml에 저장

2. **Workspace Session 시작**:
   ```
   mcp__vibe_kanban__start_workspace_session(
     task_id: "{task_id}",
     executor: "CLAUDE_CODE",
     repos: [{ repo_id: "{task의-repo-id}", base_branch: "origin/{base_branch}" }]
   )
   ```

---

## 통합 Task Description 템플릿

하나의 task에 Red→Green→Refactor 전체 워크플로우를 포함한다. 각 Step 완료 후 Review Gate에서 AskUserQuestion으로 인간 리뷰를 받고, 승인 후 다음 Step으로 진행한다.

````
🚫 **금지 사항 — 아래 규칙을 반드시 준수하세요:**
- PR 생성 시 `--base` 플래그를 반드시 아래 Context의 **Base Branch** 값으로 지정하세요. `main`을 base로 사용하지 마세요.
- 아래 Step 1부터 순서대로 실행하세요. 각 Step 완료 후 Review Gate에서 반드시 멈추고 인간의 리뷰를 받으세요.

## Context

- Linear Issue: {linear_issue_url}
- TechSpec Document: {meta.yaml의 document.url}
- **Base Branch**: `{base_branch}`
- **작업 대상 패키지**: `{package_name}` (`{package_path}`)
- **작업 디렉토리**: `{package_path}/{target_directory}`
- **기존 패턴 참조**: `{package_path}/{reference_pattern}` (같은 패키지 내 유사 모듈)
- **Linear Issue ID**: `{issue_id}` (Refactor 완료 시 Linear 동기화용)
- **Figma URL**: `{figma_url_or_null}` (TechSpec Summary에서 추출, Visual Verification용)

## 관련 테스트 케이스

{Linear TechSpec 문서에서 해당 issue의 Given/When/Then 테이블}

## 관련 설계

{Linear TechSpec 문서의 Design 섹션에서 해당 데이터 모델(Interface)/Usecase/Component 정보}

---

## Step 1: 🔴 RED — 실패하는 테스트 작성

이 Step의 목표는 **테스트만** 작성하고 **커밋**하는 것입니다.
구현 코드를 작성하지 마세요.

### 작업 순서

1. `{base_branch}`에서 브랜치 생성 (이름 규칙: issue title 기반 kebab-case)
2. Given/When/Then 테스트 케이스를 실제 테스트 코드로 변환
   - ⚠️ `describe`/`it`/`test` 설명은 **한국어**로 작성
   - ⚠️ TC#, TC1 등 번호 접두사를 붙이지 않음 — 설명만 작성
   - ⚠️ UI 렌더링 자체를 검증하는 테스트는 지양. **사용자 행동**(클릭, 입력 등)과 그 **결과**(핸들러 호출, 상태 변경, 다른 컴포넌트 노출)를 검증하는 통합 테스트 위주로 작성
   - ❌ `it('RecommendCreateAd를 렌더링한다')` → ✅ `it('광고가 없을 때 클릭하면 onCreateAd가 호출된다')`
   - 예: `describe('PostAdListItem')`, `it('광고가 0개일 때 광고 생성 유도 영역을 클릭하면 onCreateAd가 호출된다')`
   - ⚠️ 테스트 파일은 대상 소스 파일과 **같은 디렉토리**에 생성 (예: `cart.ts` → `cart.test.ts`). `__tests__/` 디렉토리를 새로 만들지 않음. 단, 프로젝트에 기존 `__tests__/` 컨벤션이 확립되어 있으면 기존 따름.
   - ⚠️ 각 테스트의 assertion은 테스트 대상의 출력/상태/부수효과를 **직접 검증**해야 함
   - ❌ `expect(true).toBe(false)`, `expect(1).toBe(2)` 등 placeholder assertion
   - ✅ `expect(result.error).toBeDefined()`, `expect(onSubmit).toHaveBeenCalledWith(...)`
   - ⚠️ mocking은 최소화. 외부 API, 타이머 등 **제어 불가능한 의존성**만 mock하고, 가능하다면 의존성 주입(DI)을 통해 실제 구현을 활용
     - 예: DB 대신 in-memory repository 주입, API client 대신 fake client 주입
3. 테스트 실행 → **실패 확인** (Red 상태)
4. 커밋

### 완료 조건

- [ ] 테스트 파일이 존재함
- [ ] 테스트 실행 시 실패함 (구현이 없으므로)

### 🔍 Review Gate 1

**반드시 여기서 멈추고 AskUserQuestion으로 인간에게 리뷰를 요청하세요.**

```
AskUserQuestion:
  question: "🔴 Red Phase 완료.

  브랜치: {branch_name}
  테스트 파일: {파일 경로 목록}
  실패하는 테스트: {N}개
  테스트 목록:
  - {it/test 설명 1} (TC #{번호})
  - {it/test 설명 2} (TC #{번호})

  리뷰 포인트:
  - 테스트 이름이 구현이 아닌 행동을 설명하는가?
  - 엣지 케이스가 포함되어 있는가?
  - TechSpec TC와 일치하는가?

  선택: 진행 (Green으로) / 수정 요청 / 중단"
```

- **수정 요청** 시 → 피드백에 따라 테스트 수정 → 커밋 → 다시 Review Gate 1
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
4. 커밋

### 완료 조건

- [ ] 해당 패키지의 **전체** 테스트 통과 (새 테스트만이 아님)
- [ ] 기존 테스트 회귀 없음 (전체 테스트 수/통과 수 보고)
- [ ] 최소한의 구현만 포함 (no gold plating)

### 🔍 Review Gate 2

**반드시 여기서 멈추고 AskUserQuestion으로 인간에게 리뷰를 요청하세요.**

```
AskUserQuestion:
  question: "🟢 Green Phase 완료.

  변경 파일:
  - {file} - {변경 요약}

  테스트: {통과}/{전체} (신규 {N}개, 기존 {N}개)

  리뷰 포인트:
  - 구현이 정말 최소한인가? (불필요한 추상화 없는가?)
  - 기존 테스트 회귀가 없는가?

  다음 단계: {Figma URL이 있고 [Presentational] 컴포넌트면 → Visual Verification / 아니면 → Refactor}

  선택: 진행 / 수정 요청 / Refactor 건너뛰기 / 중단"
```

- **수정 요청** 시 → 피드백에 따라 구현 수정 → 테스트 재실행 → 커밋 → 다시 Review Gate 2
- **진행** 시 → Visual Verification 조건 충족 시 Step 2.5로, 미충족 시 Step 3로
- **Refactor 건너뛰기** 시 → Draft PR 생성 + Linear 동기화 (상태 "In Review" + PR 코멘트) + `gh pr ready` 실행
- **중단** 시 → 작업 중지

---

## Step 2.5: 🎨 VISUAL VERIFICATION — Figma 디자인 매칭 (조건부)

> 이 Step은 **Presentational 컴포넌트 작업 + Figma URL이 있는 경우**에만 실행됩니다.
> 조건 미충족 시 "Visual Verification 건너뜀" 로그 출력 후 Step 3으로 진행하세요.

### 진입 조건

1. 위 "관련 설계"에 `[Presentational]` 컴포넌트가 포함되어 있는가?
2. Context의 **Figma URL**이 null이 아닌가?
3. 프로젝트에 Storybook (`Glob("**/.storybook")`) 또는 dev server가 있는가?

**하나라도 미충족** → "Visual Verification 조건 미충족 (사유: {미충족 항목}). Step 3으로 진행합니다." 출력 후 Step 3으로.

### 작업 순서

1. **Preview 환경 준비**:

   **Storybook 감지:**
   ```
   Glob("**/.storybook") 또는 package.json에 "@storybook/*" 의존성
   ```

   Storybook 존재 시:
   - 구현한 Presentational 컴포넌트와 같은 디렉토리에 `{Component}.stories.tsx` 생성
   - 기존 `.stories.*` 파일의 CSF 버전(CSF2/CSF3)을 확인하여 동일 형식 사용
   - Visual Contract의 각 State (default, loading, empty, error 등)를 개별 story로 작성
   - Step 1 테스트에서 사용한 mock data를 활용하여 Props 주입

   Storybook 미존재 시:
   - 프로젝트 라우팅에 맞는 preview 페이지 생성 (예: `app/dev/preview/{component}/page.tsx`)

2. **Figma 참조 이미지 캡처**:
   ```
   ToolSearch(query: "select:mcp__claude_ai_Figma__get_screenshot")
   → Figma URL에서 fileKey, nodeId 추출
   → mcp__claude_ai_Figma__get_screenshot(fileKey: "{key}", nodeId: "{id}")
   ```
   - nodeId가 URL에 없으면 `get_metadata`로 프레임 목록 조회 후 AskUserQuestion으로 선택

3. **ralph-loop로 반복 비교 & 수정**:
   ```
   Skill(skill: "ralph-loop:ralph-loop")
   ```

   ralph-loop을 사용할 수 없으면 수동으로 1회 비교 후 진행.

   각 iteration에서:
   a. 브라우저에서 Storybook/preview 페이지 스크린샷 캡처
      ```
      ToolSearch(query: "select:mcp__claude-in-chrome__tabs_context_mcp")
      → tabs_context_mcp(createIfEmpty: true)
      → navigate(url: "{preview_url}", tabId: {tabId})
      → computer(action: "screenshot", tabId: {tabId})
      ```
   b. Figma 스크린샷과 구현 스크린샷 비교 분석 (레이아웃, 색상, 타이포그래피, 간격)
   c. 차이점 수정 (CSS, 레이아웃, 디자인 토큰)
   d. 테스트 실행 → Green 유지 확인 (깨지면 revert 후 다른 방법 시도)
   e. 수렴 시 또는 최대 5회 도달 시 → ralph-loop 종료

4. **커밋**

### 완료 조건

- [ ] Storybook story 또는 preview 페이지가 생성됨
- [ ] Figma 디자인과 구현의 주요 레이아웃/색상/타이포그래피가 일치
- [ ] 모든 테스트 여전히 통과 (Green 유지)

### 🔍 Review Gate 2.5

**반드시 여기서 멈추고 AskUserQuestion으로 인간에게 리뷰를 요청하세요.**

```
AskUserQuestion:
  question: "🎨 Visual Verification 완료.

  비교 결과:
  - {component}: Figma 매칭 상태 (✅ 일치 / ⚠️ 잔여 차이: {목록})

  생성된 파일:
  - {story/preview file path}

  ralph-loop: {N}회 반복

  선택: 진행 (Refactor로) / 수정 요청 / 중단"
```

- **수정 요청** 시 → ralph-loop 재시작하여 추가 수정 → 커밋 → 다시 Review Gate 2.5
- **진행** 시 → Step 3로
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
5. 커밋 & 푸시 (첫 push):
   ```bash
   git add {changed-files}
   git commit -m "refactor: improve code quality for {task summary}"
   git push -u origin {branch-name}
   ```
6. Draft PR 생성:
   ```bash
   gh pr create --draft --base {base_branch} \
     --title "{issue title}" \
     --body "$(cat <<'EOF'
   ## TDD Progress
   - [x] 🔴 Red: 실패하는 테스트 작성
   - [x] 🟢 Green: 최소 구현
   - [x] 🎨 Visual Verification: Figma 디자인 매칭 (해당 시)
   - [x] 🔵 Refactor: 코드 개선

   ## Covered Test Cases
   - #{TC numbers from TechSpec}

   ### 리뷰 포인트
   - [ ] 테스트 케이스가 요구사항을 정확히 반영하는가?
   - [ ] 구현이 테스트 요구사항을 올바르게 충족하는가?
   - [ ] 코드 구조와 네이밍이 적절한가?
   EOF
   )"
   ```

   ⚠️ **중요**: `--base {base_branch}` 플래그 필수! `main`을 base로 사용하면 안 됩니다!

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
  테스트: {통과}/{전체} (신규 {N}개, 기존 {N}개)

  리뷰 포인트:
  - 공개 API(export 함수 시그니처, Props interface)가 변경되었는가?
  - Refactor 범위가 적절한가?

  선택: 승인 (PR을 Ready for Review로 전환) / 수정 요청"
```

- **수정 요청** 시 → 피드백에 따라 수정 → 체크 재실행 → 커밋 & 푸시 → 다시 Review Gate 3
- **승인** 시 → `gh pr ready {pr_number}` 실행 → 작업 완료
````

---

### Phase 5: 실행 상태 저장

`.claude/docs/{project-name}/implement.yaml`에 실행 상태를 저장한다:

```yaml
# .claude/docs/{project-name}/implement.yaml
executor: "vibe_kanban"
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
    - id: "{backend-repo-id}"
      name: "backend"
current_step:
  batch: 1                       # 현재 batch 번호만 추적
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
        task_id: "{vibe-task-id}"  # Task 생성 시 기록, 상태 조회에 사용
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
        task_id: null              # 다음 batch 실행 시 생성됨
created_at: "{ISO-8601}"
```

**상태 저장 시점:**

- **Task 생성 후**: `issues[].task_id` 기록, `current_step.batch` 업데이트
- **Batch 완료 확인 후** (재실행 시): `current_step.batch` → 다음 batch 번호로 업데이트

> Phase별 상태(Red/Green/Refactor)는 workspace가 내부적으로 관리하므로 implement.yaml에서 추적하지 않는다.
> Branch, PR 정보도 workspace가 관리하므로 저장하지 않는다.

### Phase 6: 결과 보고

#### Batch 시작 시

```
Batch 1 시작

Project: {Project Name}
TechSpec: {document URL}

워크스페이스 생성됨:
- [Frontend] Cart UI Component → task 생성 + session 시작
- [Backend] Cart Interface → task 생성 + session 시작

각 워크스페이스가 Red→Green→Refactor를 순차 처리합니다.
각 Phase 사이에 Review Gate에서 리뷰 요청이 옵니다.
```

#### 재실행 시 (상태 확인)

```
Batch 1 상태 확인

vk issue 상태:
- [Frontend] Cart UI Component → ✅ completed
- [Backend] Cart Interface → ⏳ in_progress

다음 단계:
- 진행 중인 워크스페이스의 Review Gate에 응답해주세요
- 모든 task 완료 후 /tdd:implement 로 Batch 2를 시작합니다
```

#### Batch 전환 시

```
Batch 1 모든 task 완료!

다음: Batch 2 (Related issues)
- [Frontend] Wishlist 저장 기능
- [Backend] Cart 미니 뷰

진행할까요?
```

## Error Handling

| 상황 | 대응 |
|------|------|
| meta.yaml 없음 | `/tdd:spec`을 먼저 실행하라고 안내 |
| Linear issue 조회 실패 | `/tdd:issues`를 먼저 실행하라고 안내 |
| "tdd" label issue 없음 | `/tdd:issues`를 먼저 실행하라고 안내 |
| Vibe Kanban 프로젝트 없음 | AskUserQuestion으로 프로젝트 선택 또는 생성 안내 |
| Repo 정보 없음 | AskUserQuestion으로 repo 선택 요청 |
| Session 시작 실패 | 에러 로그 출력, 수동 재시도 안내 |
| vk issue 상태 조회 실패 | 에러 로그 + 수동 확인 안내 |
| 모든 구현 완료 (done) | "모든 배치가 완료되었습니다" 안내 |
| Figma 스크린샷 실패 | Visual Verification 건너뛰고 Refactor로 진행 |
| Storybook/dev server 미감지 | Visual Verification 건너뛰고 Refactor로 진행 |
| claude-in-chrome 미사용 가능 | Visual Verification 건너뛰고 Refactor로 진행 |
| ralph-loop 실패 | 수동 1회 비교 후 Refactor로 진행 |
| Visual 수정으로 테스트 실패 | 수정 revert → 다른 방법 시도 |
| 최대 5회 반복 후 차이 남음 | 남은 차이 목록과 함께 사용자 결정 요청 |

## Example: 첫 실행 → Batch 1 task 생성

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

  Batch 1 (Red→Green→Refactor, 각 phase 후 리뷰)
  - [Backend] Cart Interface 및 상수 정의
  - [Frontend] Cart UI Component
  - [Backend] Cart API 엔드포인트

사용자: 진행

Claude: Vibe Kanban에 task 생성 중... (3개 tasks, 전체 TDD 워크플로우 포함)
Claude: Workspace session 시작 중...

Claude:
  Batch 1 시작

  Project: my-feature
  TechSpec: https://linear.app/daangn/document/fe-techspec-xxx
  Repos: Frontend, Backend API
  Base Branch: feature/new-cart

  워크스페이스:
  - [Backend] Cart Interface 및 상수 정의 → task 생성 + session 시작
  - [Frontend] Cart UI Component → task 생성 + session 시작
  - [Backend] Cart API 엔드포인트 → task 생성 + session 시작

  각 워크스페이스가 Red→Green→Refactor를 순차 처리합니다.
  각 Phase 완료 시 Review Gate에서 리뷰 요청이 옵니다.
```

## Example: 재실행 → 상태 확인 → Batch 2 시작

```
사용자: /tdd:implement

Claude: .claude/docs/my-feature/implement.yaml 을 발견했습니다.
Claude: Batch 1 상태 확인 중...
  vk issue 상태 조회:
  - Cart Interface 및 상수 정의 → completed ✅
  - Cart UI Component → completed ✅
  - Cart API 엔드포인트 → completed ✅

Claude: Batch 1 모든 task 완료!

Claude: [AskUserQuestion] Batch 2를 시작할까요?

  Batch 2 (Red→Green→Refactor, 각 phase 후 리뷰)
  - [Frontend] Wishlist 저장 기능
  - [Backend] Cart 미니 뷰

사용자: 진행

Claude: Vibe Kanban에 task 생성 중... (2개 tasks)
Claude: Workspace session 시작 중...

Claude:
  Batch 2 시작

  워크스페이스:
  - [Frontend] Wishlist 저장 기능 → task 생성 + session 시작
  - [Backend] Cart 미니 뷰 → task 생성 + session 시작
```

## 참고

- **단일 Task, 전체 워크플로우**: 각 issue당 하나의 vk task를 생성하며, Red→Green→Visual Verification(조건부)→Refactor 전체 지시사항을 포함
- **Workspace 자율 실행**: workspace agent가 phase를 자체 관리하고, phase 사이에 AskUserQuestion Review Gate로 인간 리뷰
- **vk update_issue 없음**: vk task는 한번 생성 후 변경하지 않음 (Linear 동기화는 Refactor 완료 시에만 수행: 상태 "In Review" 전환 + PR 링크 코멘트)
- **상태 확인 기반 진행**: `/tdd:implement` 재실행 시 vk issue 상태를 확인하여 batch 진행 여부 결정
- `--base` 파라미터로 implement.yaml의 base_branch를 override 가능
- 하나의 PR이 전체 TDD 사이클을 포함: Red→Green→Visual Verification(조건부)→Refactor 완료 후 Draft PR 생성, 최종 승인 시 Ready for Review로 전환
- **Visual Verification**: Figma URL과 Presentational 컴포넌트가 있는 경우 Green 후 Storybook/Preview를 생성하고 ralph-loop으로 Figma와 반복 비교
