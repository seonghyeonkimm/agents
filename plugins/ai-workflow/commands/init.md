프로젝트의 AI Workflow를 초기화합니다.

`.ai-workflow/init.sh`가 있으면 실행하고, 없으면 setup을 안내합니다.

---

## 1. 설정 파일 확인 및 init.sh 실행

```bash
# config.json과 init.sh 존재 확인
if [ ! -f ".ai-workflow/config.json" ]; then
    echo "⚠️ config.json이 없습니다. /ai-workflow:setup을 먼저 실행해주세요."
elif [ ! -f ".ai-workflow/init.sh" ]; then
    echo "⚠️ init.sh가 없습니다. /ai-workflow:setup을 먼저 실행해주세요."
else
    bash .ai-workflow/init.sh
fi
```

**참고:** init.sh는 내부적으로 개발 서버를 백그라운드(`nohup ... &`)로 실행합니다.
서버 시작 대기(최대 30초)가 있으므로 완료까지 시간이 걸릴 수 있습니다.

---

## 2. Linear 작업 상태 조회

init.sh 실행 후, Linear에서 현재 작업 상태를 조회합니다.

**먼저 `.ai-workflow/config.json`을 읽어서 Linear 연결 정보를 확인합니다:**

```json
{
  "linear": {
    "teamId": "...",
    "teamKey": "...",      // <- 이 값을 team 파라미터로 사용
    "projectId": "...",    // <- 이 값을 project 파라미터로 사용 (없으면 생략)
    "labels": {
      "workflow": "ai-workflow"  // <- 이 값을 label 파라미터로 사용
    }
  }
}
```

**그 다음 `mcp__linear__list_issues` 호출:**
- team: config의 `teamKey`
- project: config의 `projectId` (있는 경우)
- label: config의 `labels.workflow` (보통 `ai-workflow`)
- limit: 10

---

## 3. 결과 보고

다음 형식으로 보고합니다:

---

**🤖 AI Workflow 초기화 완료**

**프로젝트 상태:**
- Lint: {pass/fail/skipped}
- Typecheck: {pass/fail/skipped}
- Dev Server: {running/failed/already_running}

**개발 서버:** http://localhost:{port}

---

**📋 Linear 작업 현황**

| 상태 | 이슈 |
|------|------|
| 🔵 In Progress | {issue_title} |
| ⚪ Todo | {issue_title} |
| ✅ Done | {issue_title} |

**추천 작업:**
- {다음으로 진행할 이슈 제안}

---
