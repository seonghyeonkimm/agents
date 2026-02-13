---
name: tdd/start
description: 버그 수정이나 간단한 기능 추가를 위한 경량 TDD 워크플로우 (Red-Green-Refactor with human review)
arguments:
  - name: task
    description: 작업 설명 (텍스트, Linear 이슈 URL, 또는 GitHub 이슈 URL)
    required: false
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - Glob
  - Grep
  - AskUserQuestion
  - ToolSearch
---

# TDD Start Command

간단한 버그 수정이나 작은 기능 추가를 TDD로 진행한다. 분석→설계→Red→Green→Refactor 전체 사이클을 한 세션에서 처리하며, Draft PR로 진행을 추적하고, 각 phase마다 사용자 리뷰를 받는다.

heavyweight flow(`/tdd:spec` → `/tdd:design` → `/tdd:issues` → `/tdd:implement`)와 달리 Linear, Notion, Figma, Vibe Kanban 등 외부 서비스가 불필요하다.

## Usage

```
/tdd:start [task description or URL]
```

### Examples

```bash
# 텍스트로 작업 설명
/tdd:start 장바구니에 수량 음수가 입력되는 버그 수정

# GitHub 이슈 URL
/tdd:start https://github.com/org/repo/issues/42

# Linear 이슈 URL
/tdd:start https://linear.app/team/issue/TEAM-123

# 인자 없이 실행 (대화형으로 입력)
/tdd:start
```

## Prerequisites

- **필수**: 프로젝트에 테스트 프레임워크가 설정되어 있어야 함 (자동 감지)
- **필수 아님**: Linear, Notion, Figma, Vibe Kanban (외부 서비스 불필요)

## 세션 상태 관리

`.claude/docs/{project_name}/tdd-session.yaml`에 세션 상태를 저장한다. context가 압축되거나 세션이 길어져도 상태를 유지할 수 있다.

### 상태 파일 구조

```yaml
# .claude/docs/{project_name}/tdd-session.yaml
task: "버그 수정: 장바구니 수량 음수 허용됨"
branch: "fix/cart-negative-quantity"
pr:
  number: 42
  url: "https://github.com/org/repo/pull/42"
phase: "plan"  # plan | red | green | refactor | done
design:
  test_cases:
    - "Given 수량 -1 / When 장바구니 추가 / Then 에러"
  approach:
    - file: "src/domain/cart.ts"
      change: "addItem()에 수량 validation 추가"
test_files:
  - src/__tests__/cart.test.ts
source_files:
  - src/domain/cart.ts
commits:
  red: null
  green: null
  refactor: null
created_at: "2026-02-11T10:00:00Z"
updated_at: "2026-02-11T10:00:00Z"
```

### 상태 파일 규칙

- **Phase 전환 시마다 업데이트**: phase 필드, 파일 목록, 커밋 해시 등
- **커맨드 시작 시 존재 확인**: 있으면 이전 세션 이어서 진행
- **Phase 10 완료 후 삭제**: 워크플로우 정상 종료 시 정리
- **context 압축 후 복구**: 파일을 Read하여 현재 상태 복원

### project_name 결정

- 태스크 설명에서 핵심 키워드를 추출하여 kebab-case로 변환
- 예: "장바구니 수량 음수 버그" → `cart-negative-quantity`
- 기존 `.claude/docs/` 하위 디렉토리가 있으면 재사용 가능

## Execution Flow

### Phase 0: 세션 복구 확인

1. `Glob(".claude/docs/*/tdd-session.yaml")`로 기존 세션 파일 탐색

2. **파일이 존재하면** → Read하여 상태 로드 후 AskUserQuestion:
   ```
   question: "이전 TDD 세션이 발견되었습니다.

   작업: {task}
   PR: {pr_url}
   현재 단계: {phase}
   상태 파일: .claude/docs/{project_name}/tdd-session.yaml

   선택:
   - 이어서 진행: 현재 단계부터 계속합니다
   - 처음부터 다시: 상태 파일을 삭제하고 새로 시작합니다
   - 취소: 아무것도 하지 않습니다"
   ```

3. **파일이 없으면** → Phase 1로 진행

### Phase 1: 입력 수집 및 컨텍스트 파악

1. **입력 파싱**: `$ARGUMENTS.task` 분석

   | 입력 타입 | 감지 방법 | 처리 |
   |-----------|-----------|------|
   | 없음 | `$ARGUMENTS.task` 비어있음 | AskUserQuestion: "어떤 작업을 TDD로 진행할까요?" |
   | 일반 텍스트 | URL 패턴 아님 | 그대로 작업 설명으로 사용 |
   | Linear URL | `linear.app` 포함 | ToolSearch로 Linear MCP fetch (best-effort) |
   | GitHub URL | `github.com/.*/issues/` 패턴 | `gh issue view {url} --json title,body` |

   - Linear/GitHub URL fetch 실패 시 → AskUserQuestion으로 텍스트 입력 요청

2. **프로젝트 컨텍스트 수집**:

   **테스트 프레임워크 감지:**
   ```
   Glob("vitest.config.*") → vitest
   Glob("jest.config.*") 또는 package.json의 jest 섹션 → jest
   Glob("pytest.ini") 또는 Glob("pyproject.toml") → pytest
   Glob("go.mod") → go test
   ```
   - 감지 실패 시 AskUserQuestion으로 질문

   **기존 테스트 패턴 파악:**
   - Grep로 `describe(`, `it(`, `test(` 등 검색하여 테스트 파일 위치, 네이밍 컨벤션 파악
   - 대표 테스트 파일 1-2개 Read하여 import 패턴, 구조 확인

   **린터/타입체커 감지:**
   ```
   Glob("biome.json") → biome
   Glob(".eslintrc.*") 또는 Glob("eslint.config.*") → eslint
   Glob("tsconfig.json") → tsc
   ```

3. **스코프 판단**: 10개 이상의 테스트 케이스가 필요하거나 다수 모듈에 걸치는 작업이면 AskUserQuestion으로 heavyweight flow 추천

4. **세션 상태 파일 초기 생성**:
   - project_name 결정 (태스크에서 키워드 추출, kebab-case)
   - `.claude/docs/{project_name}/` 디렉토리가 없으면 생성
   - `.claude/docs/{project_name}/tdd-session.yaml` 작성 (phase: "plan")

### Phase 2: 분석 & 설계

`/tdd:spec`의 테스트 케이스 설계 + `/tdd:design`의 구현 방향을 경량화하여 하나의 phase로 합침.

1. **문제 분석**:
   - 버그인 경우: 원인 파악, 재현 조건 정리
   - 기능 추가인 경우: 요구사항 정리, 기존 코드와의 관계 파악
   - 영향 범위 파악 (어떤 파일/모듈에 영향)
   - 관련 코드 읽기 (Grep/Read로 현재 구현 확인)

2. **테스트 케이스 설계** (← `/tdd:spec`의 경량 버전):
   - Given/When/Then 형식으로 테스트 케이스 목록 작성
   - 정상 → 에러 → 엣지 케이스 순서로 나열

3. **구현 접근 방식** (← `/tdd:design`의 경량 버전):
   - 어떤 파일을 수정/생성할지
   - 어떤 함수/컴포넌트를 변경할지
   - 주의할 점 (부작용, 호환성 등)

4. **세션 상태 업데이트**: design 섹션에 테스트 케이스 & 구현 접근 기록

5. **AskUserQuestion으로 설계 리뷰 요청**:
   ```
   question: "분석 & 설계가 완료되었습니다.

   ## 문제 분석
   {문제 요약}

   ## 테스트 케이스
   1. Given {조건} / When {행동} / Then {결과}
   2. Given {조건} / When {행동} / Then {결과}

   ## 구현 접근
   - {file}: {변경 내용}
   - {file}: {변경 내용}

   선택: 진행 / 수정 요청 / 중단"
   ```

   수정 요청 시 → 설계 수정 후 상태 파일 업데이트 → 다시 리뷰 요청 (루프)

### Phase 3: Red - 실패하는 테스트 작성

0. **작업 디렉토리 확인**: `git status`로 미커밋 변경사항 확인
   - 변경사항이 있으면 AskUserQuestion: "커밋되지 않은 변경이 있습니다. stash / commit / 중단 중 선택하세요"
   - stash 선택 시 `git stash push -m "tdd-start: before {task}"`

1. Phase 2에서 설계한 테스트 케이스를 실제 테스트 코드로 변환
   - ⚠️ `describe`/`it`/`test` 설명은 **한국어**로 작성
   - 예: `describe('CartPage')`, `it('장바구니가 비어있으면 빈 상태 메시지를 표시한다')`
2. 프로젝트 컨벤션에 맞는 테스트 파일 생성/수정
3. 테스트 실행 → **실패 확인**
   - ⚠️ import 에러나 syntax 에러가 아닌 **assertion 실패**여야 함
   - import 에러가 발생하면 import/mock 설정을 수정하여 assertion 실패 상태로 맞춤

4. **branch 생성, commit & push, Draft PR 생성**:

   **Branch 이름 규칙:**
   - 버그 수정: `fix/{task-keywords}` (예: `fix/cart-negative-quantity`)
   - 기능 추가: `feat/{task-keywords}` (예: `feat/add-wishlist-button`)
   - task keywords는 project_name과 동일한 kebab-case 사용

   ```bash
   git checkout -b {branch-name}
   git add {test-files}
   git commit -m "test: add failing tests for {task summary}"
   git push -u origin {branch-name}
   gh pr create --draft --title "{task title}" --body "{PR template}"
   ```

5. **PR description 템플릿**:
   ```markdown
   ## TDD Progress
   - [x] Red: 실패하는 테스트 작성
   - [ ] Green: 최소 구현
   - [ ] Refactor: 코드 개선

   ## 작업 설명
   {task description}

   ## 테스트 케이스
   {Given/When/Then list from Phase 2}

   ## 구현 접근
   {approach from Phase 2}
   ```

6. **세션 상태 업데이트**: phase → "red", branch, pr 정보, test_files, commits.red 기록

### Phase 4: (Human) Red 리뷰

```
AskUserQuestion:
  question: "Red Phase 완료. Draft PR을 생성했습니다.

  PR: {pr_url}
  테스트 파일: {path}
  테스트 케이스:
  1. {test name} - {description}
  2. {test name} - {description}

  선택: 진행 / 수정 요청 / 중단"
```

수정 요청 시 → 테스트 수정 → 재실행(실패 확인) → commit & push → 다시 리뷰 요청 (루프)

### Phase 5: Green - 최소 구현

1. 테스트를 통과시키는 **최소한의 코드**만 작성

2. **의도적으로 피할 것:**
   - 조기 최적화
   - 테스트에 없는 케이스 처리
   - 리팩토링이나 코드 정리
   - 필요 이상의 추상화

3. 대상 테스트 실행 → 통과 확인
4. 전체 테스트 실행 → 회귀 없음 확인
5. 타입 체크 실행 (해당 시):
   ```bash
   npx tsc --noEmit  # 또는 프로젝트에 맞는 타입 체커
   ```

6. **commit & push → Draft PR 업데이트**:
   ```bash
   git add {changed-files}
   git commit -m "feat: minimal implementation for {task summary}"
   git push
   ```

7. **PR description 체크리스트 업데이트** (`gh pr edit`):
   ```markdown
   - [x] Red: 실패하는 테스트 작성
   - [x] Green: 최소 구현
   - [ ] Refactor: 코드 개선
   ```

8. **세션 상태 업데이트**: phase → "green", source_files, commits.green 기록

### Phase 6: (Human) Green 리뷰

```
AskUserQuestion:
  question: "Green Phase 완료. Draft PR이 업데이트되었습니다.

  PR: {pr_url}
  변경 파일:
  1. {file} - {변경 요약}
  2. {file} - {변경 요약}

  모든 테스트 통과.
  선택: 진행 / 수정 요청 / Refactor 건너뛰기 / 중단"
```

- 수정 요청 시 → 구현 수정 → 테스트 재실행 → commit & push → 다시 리뷰 (루프)
- **Refactor 건너뛰기** 선택 시 → Phase 7을 건너뛰고 Phase 8로 직행

### Phase 7: Refactor - 코드 개선

1. **리팩토링 기준** (우선순위):
   - 중복 제거
   - 네이밍 개선
   - 구조 정리 (파일/모듈 위치)
   - 단순화 (불필요한 복잡도 제거)
   - 프로젝트 컨벤션 정렬

2. 각 리팩토링 단계마다 테스트 재실행 → **녹색 유지 확인**

3. 최종 품질 체크 (프로젝트에서 감지된 도구 사용):
   ```bash
   # 타입 체크 (해당 시)
   npx tsc --noEmit

   # 린트 (해당 시)
   npx biome check .  # 또는 npx eslint .

   # 전체 테스트
   npx vitest run  # 또는 npx jest, pytest 등
   ```

4. **commit & push → Draft PR 업데이트**:
   ```bash
   git add {changed-files}
   git commit -m "refactor: improve code quality for {task summary}"
   git push
   ```

5. **PR description 체크리스트 완료** (`gh pr edit`):
   ```markdown
   - [x] Red: 실패하는 테스트 작성
   - [x] Green: 최소 구현
   - [x] Refactor: 코드 개선
   ```

6. **세션 상태 업데이트**: phase → "refactor", commits.refactor 기록

### Phase 8: 최종 보고

세션 상태 파일에서 정보를 읽어 최종 보고를 작성한다:

```
## TDD 완료 보고

### 작업: {task description}
### PR: {pr_url}

### 분석 & 설계
- 테스트 케이스: {N}개 설계
- 구현 접근: {summary}

### Red Phase
- 테스트 파일: {path}
- 커밋: {commit hash} - test: add failing tests

### Green Phase
- 변경 파일: {file list with summaries}
- 커밋: {commit hash} - feat: minimal implementation

### Refactor Phase
- 리팩토링: {items or "건너뛰기됨"}
- 커밋: {commit hash} (해당 시)

### 최종 검증
- 타입 체크: 통과/해당없음
- 린트: 통과/해당없음
- 테스트: {passed}/{total} 통과

### 변경된 파일 전체
- {file} (신규/수정)
```

### Phase 9: (Human) 최종 리뷰

```
AskUserQuestion:
  question: "TDD 워크플로우가 완료되었습니다.

  PR: {pr_url}

  선택: 승인 (PR을 Ready for Review로 전환) / 수정 요청"
```

수정 요청 시 → 수정 → commit & push → 다시 최종 리뷰 (루프)

### Phase 10: PR Ready for Review & 정리

1. 사용자 승인 후 Draft PR을 Ready for Review로 전환:
   ```bash
   gh pr ready {pr_number}
   ```

2. **세션 상태 파일 삭제**: `.claude/docs/{project_name}/tdd-session.yaml` 제거

3. 완료 메시지 출력:
   ```
   PR이 Ready for Review로 전환되었습니다: {pr_url}
   TDD 세션이 정리되었습니다.
   ```

## Error Handling

| 상황 | 대응 |
|------|------|
| 테스트 프레임워크 감지 실패 | AskUserQuestion으로 어떤 프레임워크를 사용하는지 질문 |
| Linear/GitHub URL fetch 실패 | 텍스트로 작업 내용 직접 입력 요청 |
| Red Phase에서 import 에러 | import/mock 설정 수정 후 assertion 실패 상태로 맞춤 |
| Green Phase 3회 시도 후 실패 | AskUserQuestion으로 접근 방법 논의 |
| 전체 테스트 회귀 | 어떤 기존 테스트가 깨졌는지 표시, 대응 방법 논의 |
| git push 실패 | 에러 표시, 수동 해결 안내 |
| 태스크가 너무 큰 경우 | `/tdd:spec` → `/tdd:design` → `/tdd:issues` → `/tdd:implement` 추천 |
| 사용자 중단 | 변경 파일 & PR URL 표시, tdd-session.yaml 유지 (나중에 재개 가능) |
| 세션 상태 파일 손상 | tdd-session.yaml 삭제 후 처음부터 시작 안내 |
| 작업 디렉토리에 미커밋 변경 있음 | AskUserQuestion으로 stash / commit / 중단 선택 |

## Example

```
사용자: /tdd:start 장바구니에 수량 음수가 입력되는 버그 수정

Claude: 프로젝트 컨텍스트를 수집합니다...
  테스트 프레임워크: vitest
  린터: biome
  타입 체커: tsc

Claude: [Phase 2] 분석 & 설계

  ## 문제 분석
  Cart.addItem()에서 수량 validation이 없어 음수 입력이 가능

  ## 테스트 케이스
  1. Given 수량 -1 / When addItem / Then ValidationError
  2. Given 수량 0 / When addItem / Then ValidationError
  3. Given 수량 1 / When addItem / Then 정상 추가

  ## 구현 접근
  - src/domain/cart.ts: addItem()에 수량 > 0 validation 추가

  [AskUserQuestion] 선택: 진행 / 수정 요청 / 중단

사용자: 진행

Claude: [Phase 3] Red - 실패하는 테스트 작성
  branch 생성: fix/cart-negative-quantity
  테스트 파일 생성: src/__tests__/cart.test.ts
  테스트 실행: 3개 실패 (expected)
  Draft PR 생성: https://github.com/org/repo/pull/42

Claude: [Phase 4] AskUserQuestion
  Red Phase 완료. 선택: 진행 / 수정 요청 / 중단

사용자: 진행

Claude: [Phase 5] Green - 최소 구현
  src/domain/cart.ts 수정: addItem()에 validation 추가
  테스트 실행: 3개 통과
  전체 테스트: 회귀 없음
  Draft PR 업데이트됨

Claude: [Phase 6] AskUserQuestion
  Green Phase 완료. 선택: 진행 / 수정 요청 / Refactor 건너뛰기 / 중단

사용자: Refactor 건너뛰기

Claude: [Phase 8] 최종 보고
  ## TDD 완료 보고
  작업: 장바구니 수량 음수 버그
  PR: https://github.com/org/repo/pull/42
  테스트: 3개 추가, 전체 통과
  Refactor: 건너뛰기됨

Claude: [Phase 9] AskUserQuestion
  선택: 승인 (Ready for Review) / 수정 요청

사용자: 승인

Claude: [Phase 10] PR Ready for Review
  PR이 Ready for Review로 전환되었습니다.
  https://github.com/org/repo/pull/42
  TDD 세션이 정리되었습니다.
```

## 참고

- 이 커맨드는 현재 워크스페이스에서 직접 실행됨 (병렬 워크스페이스 생성 안함)
- 커밋은 각 phase별로 자동 생성됨 (Red/Green/Refactor)
- 세션 중단 후 `/tdd:start`를 다시 실행하면 이전 진행 상태에서 재개 가능
- Refactor phase는 건너뛸 수 있음 (사소한 수정 시)
- 최종 승인 전까지 PR은 Draft 상태를 유지함
