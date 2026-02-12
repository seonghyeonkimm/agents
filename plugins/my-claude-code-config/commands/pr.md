---
description: 현재 변경사항을 커밋하고 PR을 생성합니다. 인자 없으면 draft PR, "ready"면 ready-for-review PR.
allowed-tools:
  - Bash
---

# PR 생성 Command

현재 작업 브랜치의 변경사항을 커밋하고 GitHub PR을 생성합니다.

## 인자

- 인자 없음: draft PR 생성
- `ready`: ready-for-review PR 생성
- PR URL 또는 번호: 해당 PR에 변경사항 push (새 PR 생성하지 않음)

## Execution Flow

### Step 0: GitHub 계정 확인 (gh auth)

⚠️ gh 명령어 실행 전 반드시 올바른 계정이 활성화되어 있는지 확인한다.

1. **GITHUB_TOKEN 환경변수 확인** (최우선):
   - `echo $GITHUB_TOKEN`으로 설정 여부 확인
   - GITHUB_TOKEN이 설정되어 있으면 gh CLI는 이 토큰만 사용하고 `gh auth switch`를 무시함
   - 설정되어 있다면: 이후 모든 `gh` 명령어 앞에 반드시 `unset GITHUB_TOKEN &&`를 붙여 실행
2. `git remote get-url origin`으로 remote URL에서 소유자(org/user)를 파싱
3. 소유자-계정 매핑:
   - `seonghyeonkimm/*` → `seonghyeonkimm` 계정
   - 그 외 (`karrot-emu/*` 등) → `roger_karrot` 계정
4. `gh api user --jq '.login'`으로 현재 활성 계정 확인 (GITHUB_TOKEN이 있었다면 unset 후 확인)
5. 매핑된 계정과 활성 계정이 다르면:
   - `gh auth switch -u {올바른_계정}` 실행
   - 전환 성공 확인 후 다음 단계 진행
6. 전환 실패 시: 에러 메시지 출력하고 `gh auth login` 안내

### Step 1: 상태 확인
1. `git status`로 변경사항 확인
2. `git diff --stat`로 변경 파일 확인
3. `git log --oneline -5`로 최근 커밋 스타일 확인
4. 변경사항이 없으면 "커밋할 변경사항이 없습니다." 출력 후 종료

### Step 2: 기존 PR Push 모드 (PR URL/번호가 인자로 제공된 경우)
1. 변경된 파일을 staging
2. 변경 내용을 분석하여 커밋 메시지 작성
3. `git push`로 기존 PR 브랜치에 push
4. PR URL 출력 후 종료

### Step 3: 새 PR 생성 모드
1. 변경된 파일을 staging (.env, credentials 등 민감파일 제외)
2. 변경 내용을 분석하여 커밋 메시지 작성
3. 커밋 생성
4. 원격에 push (`git push -u origin HEAD`)
5. `gh pr create` 실행:
   - `--draft` (기본) 또는 ready 모드
   - 제목: 70자 이내, 변경 핵심 요약
   - 본문: Summary bullet points + Test plan
6. PR URL 출력

## 커밋 메시지 규칙
- 변경 성격을 정확히 반영 (add/update/fix/refactor)
- 1-2문장, "why" 중심
- Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>

## PR 본문 형식
```
## Summary
- {변경사항 1}
- {변경사항 2}

## Test plan
- [ ] {테스트 항목}

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```
