Linear에서 프로젝트 상태를 확인하고 작업 컨텍스트를 설정합니다.

이 명령어가 호출되면 다음 단계를 순서대로 수행하세요:

## 0. 설정 파일 확인 (CRITICAL)

먼저 `.ai-workflow/config.json` 파일이 존재하는지 확인합니다:

```bash
cat .ai-workflow/config.json 2>&1
```

**설정 파일이 없는 경우 즉시 중단:**

---

**Linear 설정이 필요합니다**

`.ai-workflow/config.json` 파일이 없습니다.

먼저 `/ai-workflow:setup` 명령어를 실행하여 Linear 연결을 설정해주세요.

---

**중요: 설정 파일이 없으면 아래 단계를 절대 진행하지 마세요.**

---

## 1. Linear 연결 확인

config.json에서 설정을 읽고 Linear 연결을 확인합니다:

```
mcp__linear__get_team:
  query: {teamId from config}
```

팀 정보를 정상적으로 가져오면 연결 성공입니다.

---

## 2. 현재 작업 목록 조회

`mcp__linear__list_issues` 도구를 사용하여 작업 목록을 가져옵니다:

```
mcp__linear__list_issues:
  team: {teamKey}
  project: {projectId}  # config에 있으면
  label: "ai-workflow"  # 워크플로우 라벨이 있는 이슈만
  includeArchived: false
  limit: 20
```

**작업 상태별 분류:**
- `In Progress` 상태 이슈 → 현재 진행 중
- `Todo` / `Backlog` 상태 이슈 → 대기 중
- `Done` / `Completed` 상태 이슈 → 완료

---

## 3. 최근 활동 파악

최근 업데이트된 이슈 3개를 조회하여 작업 맥락을 파악합니다:

```
mcp__linear__list_issues:
  team: {teamKey}
  label: "ai-workflow"
  orderBy: "updatedAt"
  limit: 3
```

각 이슈의 최근 코멘트도 확인합니다:

```
mcp__linear__list_comments:
  issueId: {issue_id}
```

---

## 4. 요약 보고

모든 단계를 완료한 후, 다음 형식으로 요약을 제공합니다:

---

**프로젝트 초기화 완료**

**Linear 연결:** {team_name} (`{team_key}`)

**작업 목록:**
| 상태 | 개수 |
|------|------|
| 진행 중 | {in_progress_count}개 |
| 대기 | {pending_count}개 |
| 완료 | {done_count}개 |

**현재 진행 중인 작업:**
- [{issue_key}] {issue_title}

**최근 활동 (최근 3개):**
1. [{issue_key}] {title} - {updated_at}
2. [{issue_key}] {title} - {updated_at}
3. [{issue_key}] {title} - {updated_at}

**다음 추천 작업:**
- [{issue_key}] {title} (우선순위: {priority})

---

## 5. 다음 단계 안내

사용자가 바로 작업을 시작할 수 있도록 안내합니다:

> 작업을 시작하려면:
> - 진행 중인 작업 계속: 해당 이슈 내용을 확인하고 작업 진행
> - 새 작업 시작: `/ai-workflow:recommend-agent`로 적합한 agent 추천받기
> - 새 기능 추가: `/ai-workflow:add-feature`로 새 이슈 생성

---

## 주의사항

- Linear MCP 연결이 필요합니다
- config.json의 teamId, projectId를 사용합니다
- `ai-workflow` 라벨이 있는 이슈만 조회합니다
- 이슈가 없으면 `/ai-workflow:add-feature`로 새 작업 추가를 안내하세요
