Linear와 연동하여 AI 워크플로우를 설정합니다.

이 명령어는 Linear 프로젝트와 연결하고 필요한 설정을 구성합니다.

---

## 0. 폴더 생성 및 기존 설정 확인

```bash
# .ai-workflow 폴더 생성
mkdir -p .ai-workflow

# 기존 설정 파일 확인
ls -la .ai-workflow/config.json 2>&1
```

이미 `config.json`이 존재하면 사용자에게 알리고 덮어쓸지 확인하세요.

---

## 1. Linear 팀 선택

`mcp__linear__list_teams` 도구를 사용하여 사용 가능한 팀 목록을 조회합니다.

**사용자에게 팀 선택 요청:**

> Linear에서 사용할 팀을 선택해주세요:
>
> | # | 팀 이름 | Key |
> |---|---------|-----|
> | 1 | {team_name} | {team_key} |
> | 2 | {team_name} | {team_key} |

선택된 팀의 `id`와 `key`를 기록합니다.

---

## 2. Linear 프로젝트 선택 (선택사항)

`mcp__linear__list_projects` 도구를 사용하여 해당 팀의 프로젝트 목록을 조회합니다.

**사용자에게 프로젝트 선택 요청:**

> 작업을 관리할 프로젝트를 선택해주세요 (선택사항):
>
> | # | 프로젝트 이름 | 상태 |
> |---|--------------|------|
> | 0 | (프로젝트 없이 팀 전체 이슈 사용) | - |
> | 1 | {project_name} | {state} |

프로젝트를 선택하지 않으면 팀 전체 이슈를 대상으로 작업합니다.

---

## 3. 워크플로우 라벨 확인/생성

`mcp__linear__list_issue_labels` 도구로 기존 라벨을 확인하고, 필요한 라벨이 없으면 생성합니다.

**필요한 라벨:**
- `ai-workflow` - AI 워크플로우로 관리되는 이슈 표시
- `spec-needed` - 스펙 문서 작성이 필요한 이슈

```
# 라벨 생성 (없는 경우)
mcp__linear__create_issue_label:
  name: "ai-workflow"
  color: "#6B46C1"  # 보라색
  teamId: {selected_team_id}

mcp__linear__create_issue_label:
  name: "spec-needed"
  color: "#F59E0B"  # 주황색
  teamId: {selected_team_id}
```

---

## 4. config.json 생성

설정 정보를 `.ai-workflow/config.json`에 저장합니다:

```json
{
  "linear": {
    "teamId": "{selected_team_id}",
    "teamKey": "{selected_team_key}",
    "projectId": "{selected_project_id or null}",
    "labels": {
      "workflow": "ai-workflow",
      "specNeeded": "spec-needed"
    }
  }
}
```

---

## 5. .gitignore 업데이트

`.ai-workflow` 폴더를 git에서 제외합니다:

```bash
# .gitignore에 .ai-workflow가 없으면 추가
grep -q "^\.ai-workflow" .gitignore 2>/dev/null || echo -e "\n# AI Workflow config\n.ai-workflow/" >> .gitignore
```

---

## 6. init.sh 및 clear.sh 생성

`ai-workflow:create-setup-sh` 스킬을 사용하여 초기화 및 정리 스크립트를 생성합니다.

**init.sh** - `/ai-workflow:init` 명령어로 실행:
1. Lint/Typecheck로 프로젝트 상태 체크
2. 개발 서버 실행 (백그라운드)
3. 서버 상태 확인 후 결과 보고

**clear.sh** - `/ai-workflow:clear` 명령어로 실행:
1. init.sh에서 실행한 프로세스 종료
2. 임시 파일 정리

**스킬 실행:**
```
Skill tool: skill="ai-workflow:create-setup-sh"
```

스킬의 지시에 따라 프로젝트에 맞는 init.sh와 clear.sh를 생성하세요.

---

## 7. 완료 보고

설정 완료 후 다음 형식으로 보고합니다:

---

**AI 워크플로우 설정 완료**

**Linear 연결 정보:**
- Team: {team_name} (`{team_key}`)
- Project: {project_name or "없음 (팀 전체)"}

**생성된 라벨:**
- `ai-workflow` - 워크플로우 관리 이슈
- `spec-needed` - 스펙 작성 필요

**설정 파일:**
- `.ai-workflow/config.json`
- `.ai-workflow/init.sh`
- `.ai-workflow/clear.sh`

**다음 단계:**
- `/ai-workflow:init` 명령어로 프로젝트 초기화 및 Linear 작업 상태 확인
- `/ai-workflow:clear` 명령어로 실행 중인 프로세스 정리

---

## 주의사항

- Linear MCP 도구가 설정되어 있어야 합니다
- 팀/프로젝트 선택은 사용자 확인 후 진행
- config.json은 git에서 제외됨 (API 키 등 민감정보 보호)
- 라벨 색상은 Linear UI에서 나중에 변경 가능
