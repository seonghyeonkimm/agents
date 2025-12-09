새로운 feature를 논의하고, Linear에 이슈를 생성합니다.

이 명령어는 다음 단계를 수행합니다:
1. 사용자와 feature에 대해 논의하여 요구사항 파악
2. Linear에 이슈 생성 (스펙이 필요하면 `spec-needed` 라벨 추가)
3. 필요시 스펙 문서를 이슈 description에 작성

---

## 0. 설정 파일 확인

```bash
cat .ai-workflow/config.json 2>&1
```

설정 파일이 없으면:

---

**Linear 설정이 필요합니다**

`.ai-workflow/config.json` 파일이 없습니다.
먼저 `/ai-workflow:setup` 명령어를 실행하여 Linear 연결을 설정해주세요.

---

**파일이 없으면 여기서 중단하세요.**

---

## 1. Feature 논의 (Discovery)

사용자와 대화를 통해 feature를 명확히 합니다.

**질문 가이드:**

> 추가하려는 feature에 대해 알려주세요:
>
> 1. **기능 이름**: 이 기능을 뭐라고 부르면 좋을까요?
> 2. **목적**: 이 기능이 왜 필요한가요? 어떤 문제를 해결하나요?
> 3. **사용자 시나리오**: 사용자가 이 기능을 어떻게 사용하게 되나요?
> 4. **우선순위**: 얼마나 급한가요? (Urgent/High/Medium/Low)
> 5. **스펙 필요 여부**: 상세한 스펙 문서가 필요한가요?

**추가 질문 (필요시):**
- 기존 기능과의 관계가 있나요?
- 기술적 제약사항이 있나요?
- 예상되는 엣지 케이스가 있나요?

**명확해질 때까지 질문을 계속하세요.** 추측하지 마세요.

---

## 2. Feature 요약 확인

논의 내용을 정리하여 사용자에게 확인받습니다:

---

**Feature 요약**

| 항목 | 내용 |
|------|------|
| 기능명 | {feature_name} |
| 목적 | {purpose} |
| 우선순위 | {priority} |
| 스펙 필요 | {yes/no} |

**주요 요구사항:**
- {requirement_1}
- {requirement_2}
- {requirement_3}

이 내용이 맞나요? 수정할 부분이 있으면 알려주세요.

---

**사용자가 확인할 때까지 다음 단계로 진행하지 마세요.**

---

## 3. Linear 이슈 생성

`mcp__linear__create_issue` 도구를 사용하여 이슈를 생성합니다:

```
mcp__linear__create_issue:
  team: {teamKey from config}
  project: {projectId from config}  # 있으면
  title: {feature_name}
  description: |
    ## 목적
    {purpose}

    ## 요구사항
    - {requirement_1}
    - {requirement_2}
    - {requirement_3}

    ## 사용자 시나리오
    {scenario}
  priority: {1-4}  # 1=Urgent, 2=High, 3=Medium, 4=Low
  labels: ["ai-workflow", "spec-needed"]  # 스펙 필요시
```

**우선순위 매핑:**
| 사용자 입력 | Linear Priority |
|------------|-----------------|
| Urgent | 1 |
| High | 2 |
| Medium | 3 |
| Low | 4 |

---

## 4. 스펙 문서 작성 (선택사항)

스펙이 필요하다고 한 경우, `ai-workflow:create-spec-doc` 스킬을 사용하여 스펙을 작성합니다.

스펙 내용은 이슈의 description에 추가하거나, 별도 코멘트로 남깁니다:

```
mcp__linear__create_comment:
  issueId: {created_issue_id}
  body: |
    ## 상세 스펙

    ### 기능 설명
    {detailed_description}

    ### 구현 사항
    - [ ] {task_1}
    - [ ] {task_2}
    - [ ] {task_3}

    ### 엣지 케이스
    - {edge_case_1}
    - {edge_case_2}
```

---

## 5. 완료 보고

---

**Feature 추가 완료**

**생성된 이슈:**
- ID: `{issue_identifier}` (예: TEAM-123)
- 제목: {title}
- 우선순위: {priority}
- 상태: Backlog

**라벨:**
- `ai-workflow`
- `spec-needed` (스펙 필요시)

**Linear 링크:** {issue_url}

**다음 단계:**
- `/ai-workflow:initialize`로 작업 목록 확인
- `/ai-workflow:recommend-agent`로 적합한 agent 추천받기

---

## Sub-task 추가 (선택사항)

큰 기능을 작은 단위로 나눠야 할 경우, sub-issue를 생성합니다:

```
mcp__linear__create_issue:
  team: {teamKey}
  title: {subtask_title}
  parentId: {parent_issue_id}
  labels: ["ai-workflow"]
```

---

## 주의사항

- Feature에 대해 충분히 이해할 때까지 질문하세요
- 이슈 생성 전 사용자 확인 필수
- `ai-workflow` 라벨은 항상 추가
- 스펙이 필요한 경우 `spec-needed` 라벨 추가
- 큰 기능은 sub-issue로 분할 권장
