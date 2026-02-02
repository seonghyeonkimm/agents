# TDD Workflow Plugin Plan

## 목표

Linear 이슈에서 시작해서 테크스펙 작성 → 테스트 케이스 설계 → 도메인/컴포넌트 설계 → 태스크 분해 → TDD 구현 → PR 생성까지의 워크플로우를 자동화하는 Claude Code 플러그인.

## 워크플로우 (notes.md 기반)

### /tdd:spec
1. (Human) Linear Project, (optional) PRD, (optional) Figma 링크 붙이기. Figma, PRD가 없는 경우 정말로 없는지 유저에게 명시적으로 묻기
2. (AI) Linear Project 하위에 테크스펙 템플릿 기준으로 document 생성
3. (AI) 테크스펙 Solution 작성하기
4. (AI) Acceptance Criteria 작성하기
5. (AI) (Optional) Non-Functional Requirements 작성하기
6. (AI) Given / When / Then 테스트 케이스 작성하기
7. (AI) .claude/docs/{project-name}/progress.json에 진행 상태랑 project link 등을 결과를 기록하기
7. (Human) review

### /tdd:design ()
8. (AI) 테스트 케이스 기반으로 Domain Entity, Domain Usecase 추출하기
9. (AI) Figma 디자인 및 테스트 케이스 기반으로 Client Component 및 상태 설계하기
10. (Human) review

### /tdd:design (.claude/docs/{project-name}/progress.json파일중에 상태가 spec까지만 완료된 project를 찾거나 혹은 유저가 제공하는 param기준으로 아래 작업들을 진행하는 skill)
8. (AI) 테스트 케이스 기반으로 Domain Entity, Domain Usecase 추출하기
9. (AI) Figma 디자인 및 테스트 케이스 기반으로 Client Component 및 상태 설계하기
10. 8,9번 결과를 linear document에 테크스펙에 업데이트하기 과정도 포함시키기
11. 그리고 progress.json에 작업관련해서 업데이트하기
10. (Human) review

### /tdd:issues (spec, design 필수 -> design 관련 업데이트되어있는 linear project, document link 필수)
11. (AI) 문서 기반으로 Task 기준으로 Linear 이슈 생성하기
12. (Human) review

### /tdd:implement (spec, design, issues 필수 -> 모든게 업데이트되어있는 linear project, document link 필수)
13. (AI) 현재 병렬로 진행할 수 있는 이슈들을 판단하고 vibe kanban에 task 생성 및 session 시작. 
    - Red, Green, Refactor 방식으로 진행
    - type check, biome check, test success 필수
    - commit & draft PR 생성, linear에 PR 관련 내용 싱크 포함
14. (Human) 각각의 PR 작업 검수 및 리뷰하기

## 플러그인 구조

```
plugins/tdd-workflow/
  skills/
    techspec-template/SKILL.md         # 테크스펙 구조 + 작성 가이드
    acceptance-criteria/SKILL.md       # AC 작성 패턴
    test-case-design/SKILL.md          # Given/When/Then 패턴
    domain-modeling/SKILL.md           # Entity/Usecase 추출 패턴
    component-design/SKILL.md          # Component & State 설계 패턴
  agents/
    orchestrator.md                    # 전체 워크플로우 (subagent 호출)
    spec-writer.md                     # Solution, AC, NFR 작성
    test-designer.md                   # 테스트 케이스 설계
    architect.md                       # 도메인 + 컴포넌트 설계
    task-planner.md                    # Linear 이슈 분해
    implementer.md                     # TDD 구현 (Red/Green/Refactor)
```

## 실행 흐름

```
Orchestrator Agent
│
├─ spec-writer (subagent)
│   ├─ 참조: techspec-template skill
│   ├─ 입력: Linear 이슈, PRD, Figma
│   ├─ 출력: .claude/docs/techspec/{issue-id}/solution.md
│   └─ → human review
│
├─ spec-writer (subagent)
│   ├─ 참조: acceptance-criteria skill
│   ├─ 입력: solution.md
│   ├─ 출력: .claude/docs/techspec/{issue-id}/ac.md
│   └─ → human review
│
├─ test-designer (subagent)
│   ├─ 참조: test-case-design skill
│   ├─ 입력: ac.md
│   ├─ 출력: .claude/docs/techspec/{issue-id}/test-cases.md
│   └─ → human review
│
├─ architect (subagent)
│   ├─ 참조: domain-modeling + component-design skills
│   ├─ 입력: test-cases.md + Figma
│   ├─ 출력: .claude/docs/techspec/{issue-id}/design.md
│   └─ → human review
│
├─ task-planner (subagent)
│   ├─ 입력: 전체 docs
│   ├─ 출력: Linear 이슈 생성
│   └─ → human review
│
└─ implementer (subagent, 병렬 N개)
    ├─ 입력: Linear 태스크 1개
    ├─ 실행: Red → Green → Refactor
    └─ 출력: commit & draft PR
```

## 공유 상태: `.claude/docs/techspec/{issue-id}/`

각 subagent는 이전 단계 파일을 읽고, 자기 결과를 여기에 쓴다.

```
.claude/docs/techspec/{issue-id}/
  context.md       # Linear 이슈, PRD, Figma 링크
  solution.md      # Solution 초안
  ac.md            # Acceptance Criteria
  nfr.md           # Non-Functional Requirements (optional)
  test-cases.md    # Given/When/Then
  design.md        # Domain + Component 설계
```

## FE TechSpec 템플릿 (Linear)

참고: Linear MCP는 `issueId`, `lastAppliedTemplateId`를 지원하지 않아 이슈 하위 문서 생성/템플릿 적용 불가. 콘텐츠 생성에 집중하고, Linear 연동은 API 직접 호출로 우회 가능.

```
FE TechSpec
├── Summary (Linear, PRD, Figma 링크)
├── Solution (해결책 간략 서술)
├── Acceptance Criteria (기술 용어 없이 평가 기준)
├── Non-Functional Requirements (SLA/SLO)
├── Functional Requirements (Test cases / Given, When, Then)
│   ├── Command → Event → (Gear) → ReadModel
│   └── Entity, Command 별 Given/When/Then
└── Design
    ├── (Optional) Context & Container Diagram
    ├── Component & Code - Client
    │   ├── domain/module, entities, usecases
    │   └── Components & States
    └── (Optional) Component & Code - Server
        ├── domain/module, entities, usecases
        └── ...
```

## 점진적 작업 순서

| Phase | 만들 것 | 검증 방법 |
|-------|---------|-----------|
| **1** | `techspec-template` skill + `spec-writer` agent (Solution만) | 실제 이슈로 solution.md 생성 |
| **2** | `acceptance-criteria` skill, spec-writer에 AC 추가 | solution → ac 변환 확인 |
| **3** | `test-case-design` skill + `test-designer` agent | ac → test-cases 변환 확인 |
| **4** | `domain-modeling` + `component-design` skills + `architect` agent | test-cases → design 확인 |
| **5** | `task-planner` agent | design → Linear 이슈 확인 |
| **6** | `implementer` agent | 단일 태스크 TDD 구현 확인 |
| **7** | `orchestrator` agent | 전체 체인 + 리뷰 게이트 |

## 제약사항

- Linear MCP: `create_document`에 `issueId`, `lastAppliedTemplateId` 파라미터 미지원
- Linear API(GraphQL)는 두 기능 모두 지원하므로 직접 호출로 우회 가능
