현재 작업에 가장 적합한 subagent를 추천합니다.

이 명령어는 설치된 agent들을 분석하고, feature-list.json의 작업에 맞는 agent를 추천합니다.

## 0. 필수 파일 확인

```bash
ls -la feature-list.json 2>&1
```

`feature-list.json` 파일이 없으면:

---

**설정이 필요합니다**

`feature-list.json` 파일이 없습니다.
먼저 `/ai-workflow:setup` 명령어를 실행하여 프로젝트를 설정해주세요.

---

**파일이 없으면 여기서 중단하세요.**

---

## 1. 현재 작업 파악

`feature-list.json`을 읽어 진행할 작업을 파악합니다:

```bash
cat feature-list.json
```

**우선순위 결정:**
1. `status: "in-progress"` 인 작업이 있으면 해당 작업 선택
2. 없으면 `status: "pending"` 중 `priority: "high"` 작업 선택
3. 없으면 `status: "pending"` 중 첫 번째 작업 선택

선택된 작업의 정보를 정리하세요:
- 작업 ID 및 제목
- 설명
- 관련 스펙 문서 (specPath)
- 관련 파일들

---

## 2. 설치된 Agent 목록 파악

Claude Code에서 사용 가능한 agent들을 파악합니다.

**Built-in Agents (항상 사용 가능):**

| Agent | 설명 | 적합한 작업 |
|-------|------|------------|
| `Explore` | 코드베이스 탐색 전문 | 구조 파악, 파일 검색, 코드 이해 |
| `Plan` | 구현 계획 설계 | 아키텍처 설계, 구현 전략 수립 |
| `claude-code-guide` | Claude Code 사용법 안내 | 도구 사용법 질문 |
| `frontend-developer` | React/Next.js 프론트엔드 | UI 컴포넌트, 프론트엔드 기능 |
| `mobile-developer` | React Native/Flutter 모바일 | 모바일 앱 기능 |
| `backend-architect` | 백엔드 API 설계 | API 설계, 서비스 아키텍처 |
| `graphql-architect` | GraphQL 설계 | GraphQL 스키마, 쿼리 최적화 |
| `typescript-pro` | TypeScript 전문가 | 타입 시스템, 고급 타입 패턴 |
| `javascript-pro` | JavaScript 전문가 | JS 최적화, 비동기 패턴 |
| `code-reviewer` | 코드 리뷰 | 코드 품질, 보안 검토 |
| `docs-architect` | 기술 문서 작성 | 문서화, 아키텍처 가이드 |
| `cloud-architect` | 클라우드 인프라 | AWS/Azure/GCP 설계 |
| `kubernetes-architect` | K8s 설계 | 컨테이너 오케스트레이션 |
| `terraform-specialist` | IaC 전문가 | 인프라 자동화 |
| `tdd-orchestrator` | TDD 전문가 | 테스트 주도 개발 |

**Custom Agents 확인:**

사용자에게 설치된 커스텀 agent가 있는지 확인하세요:

> 추가로 설치한 커스텀 agent가 있나요?
> 있다면 agent 이름과 용도를 알려주세요.

---

## 3. Agent 매칭 분석

선택된 작업과 agent들을 매칭합니다.

**매칭 기준:**

1. **작업 유형 분석**
   - 프론트엔드 UI 작업 → `frontend-developer`
   - 백엔드 API 작업 → `backend-architect`
   - 타입 관련 작업 → `typescript-pro`
   - 테스트 작성 → `tdd-orchestrator`
   - 코드 리뷰 필요 → `code-reviewer`
   - 아키텍처 설계 → `Plan`
   - 코드베이스 이해 필요 → `Explore`

2. **키워드 매칭**
   - "component", "UI", "페이지", "화면" → `frontend-developer`
   - "API", "endpoint", "서버" → `backend-architect`
   - "GraphQL", "query", "mutation" → `graphql-architect`
   - "type", "interface", "제네릭" → `typescript-pro`
   - "test", "TDD", "테스트" → `tdd-orchestrator`
   - "document", "문서", "README" → `docs-architect`
   - "deploy", "infra", "배포" → `cloud-architect`

3. **specPath 분석**
   - 스펙 문서가 있으면 내용을 읽어 작업 성격 파악
   - 디자인 스펙 → `frontend-developer`
   - API 스펙 → `backend-architect`
   - 아키텍처 스펙 → `Plan`

---

## 4. 추천 결과 제공

분석 결과를 다음 형식으로 제공합니다:

---

**Agent 추천 결과**

**현재 작업:**
- ID: `{feature_id}`
- 제목: {title}
- 설명: {description}

**추천 Agent:**

| 순위 | Agent | 적합도 | 추천 이유 |
|------|-------|--------|----------|
| 1 | `{primary_agent}` | ⭐⭐⭐ | {reason} |
| 2 | `{secondary_agent}` | ⭐⭐ | {reason} |
| 3 | `{tertiary_agent}` | ⭐ | {reason} |

**추천 워크플로우:**

```
1. {first_step_with_agent}
2. {second_step_with_agent}
3. {final_step}
```

**Agent 실행 방법:**
```
Task tool 사용 시: subagent_type="{recommended_agent}"
```

---

## 5. 복합 작업 처리

작업이 여러 영역에 걸쳐있는 경우:

---

**복합 작업 감지됨**

이 작업은 여러 영역을 포함합니다:
- 프론트엔드: {frontend_tasks}
- 백엔드: {backend_tasks}

**단계별 Agent 추천:**

| 단계 | 작업 | 추천 Agent |
|------|------|-----------|
| 1 | 전체 구조 파악 | `Explore` |
| 2 | 구현 계획 수립 | `Plan` |
| 3 | 백엔드 구현 | `backend-architect` |
| 4 | 프론트엔드 구현 | `frontend-developer` |
| 5 | 코드 리뷰 | `code-reviewer` |

---

## 주의사항

- 확실하지 않은 경우 `Explore` → `Plan` 순서로 시작 추천
- 여러 agent가 동등하게 적합하면 모두 제시하고 사용자 선택 유도
- 커스텀 agent가 built-in보다 적합할 수 있으니 항상 확인
