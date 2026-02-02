---
name: techspec-template
description: FE TechSpec 문서 구조 및 섹션별 작성 가이드. 테크스펙 문서를 작성하거나 리뷰할 때 참조합니다.
globs:
  - ".claude/docs/**"
---

# FE TechSpec Template

FE 기능 개발을 위한 기술 명세서 템플릿입니다. 각 섹션은 이전 섹션의 결과물을 입력으로 받아 점진적으로 구체화됩니다.

## 전체 구조

| 순서 | 섹션 | 입력 | 출력 파일 | 작성 Phase |
|------|------|------|-----------|------------|
| 1 | Context | Linear Project | context.md | Phase 1 |
| 2 | Solution | context.md + PRD + Figma | solution.md | Phase 1 |
| 3 | Acceptance Criteria | solution.md | ac.md | Phase 2 |
| 4 | Non-Functional Requirements | solution.md | nfr.md | Phase 2 |
| 5 | Functional Requirements | ac.md | test-cases.md | Phase 3 |
| 6 | Design | test-cases.md + Figma | design.md | Phase 4 |

## 출력 디렉토리 구조

```
.claude/docs/
  {project-name}/                 # Linear Project 이름 (예: adsc, api-center 등)
    context.md                     # Linear Project, PRD, Figma 링크
    solution.md                    # Solution 섹션
    ac.md                          # Phase 2에서 추가
    nfr.md                         # Phase 2에서 추가
    test-cases.md                  # Phase 3에서 추가
    design.md                       # Phase 4에서 추가
```

---

## Section 1: Context (context.md) — Phase 1

### 목적

프로젝트와 관련된 모든 참조 링크와 기본 정보를 한 곳에 수집합니다.

### 템플릿

```markdown
# Context: {프로젝트명}

## Linear Project
- **URL**: {linear-project-url}
- **Name**: {프로젝트 이름}
- **Lead**: {담당자}
- **Status**: {상태}

## PRD (Product Requirements Document)
- **URL**: {notion-prd-url}
- **Description**: {PRD 간략 설명}

## Figma Design
- **URL**: {figma-url}
- **Description**: {디자인 간략 설명}

## Project Description
{Linear Project에서 추출한 프로젝트 설명}

## Key Information
- **Objective**: {주요 목표}
- **Timeline**: {예상 일정}
- **Priority**: {우선순위}
```

---

## Section 2: Solution (solution.md) ★ Phase 1

### 목적

문제에 대한 해결 방향을 간결하게 서술합니다. 구현 세부사항이 아닌, 접근 방식의 큰 그림을 설명합니다.

### 작성 규칙

1. **분량**: 3~10문장. 너무 짧으면 방향이 불명확하고, 너무 길면 설계 영역을 침범합니다.

2. **관점**: 사용자 문제 → 해결 접근 → 기술적 방향 순서로 작성합니다.

3. **금지 사항**:
   - 구체적인 컴포넌트명, 함수명, 변수명 사용 금지
   - 특정 라이브러리/프레임워크 언급은 최소화
   - 코드 스니펫 포함 금지

4. **필수 포함 요소**:
   - 어떤 사용자 문제를 해결하는가
   - 어떤 접근 방식을 택했는가 (그리고 왜)
   - 기존 시스템과 어떻게 통합되는가
   - 주요 트레이드오프가 있다면 간략히 언급

5. **어조**: 기술 리더가 팀에게 방향을 설명하는 톤

### 입력 소스 활용법

| 소스 | 추출할 정보 | 우선순위 |
|------|------------|----------|
| Linear Project | 프로젝트 제목, 설명, 목표 | 필수 |
| PRD (Notion) | 비즈니스 배경, 사용자 스토리, 성공 지표 | 높음 |
| Figma | 화면 흐름, 주요 인터랙션 패턴 | 보통 |

### 좋은 예시 vs 나쁜 예시

✅ **좋은 예시**:
```
사용자가 광고 캠페인을 일일이 관리하는 번거로움을 해결하기 위해, 대량 관리 도구를 제공합니다.
특정 조건(예산, 상태, 성과 지표)에 맞는 캠페인을 한 번에 선택하고, 예산 조정, 일시정지 등의
작업을 배치로 처리할 수 있도록 합니다. 기존 대시보드에 새로운 작업 영역을 추가하여 기존 워크플로우를
방해하지 않으면서도, 사용자가 필요할 때 접근할 수 있도록 설계합니다.
```

❌ **나쁜 예시**:
```
CampaignBulkManager 컴포넌트를 만들고, Redux로 상태를 관리합니다. API endpoint /campaigns/bulk-update를
호출하여 데이터를 업데이트합니다. React Query를 사용해서 캐싱을 처리합니다.
```

### 템플릿

```markdown
# Solution: {프로젝트명}

{Solution 본문 - 3~10문장}

---

**Sources**:
- Linear Project: {프로젝트명}
- PRD: {Notion 링크}
- Figma: {Figma 링크 (있는 경우)}

*Generated*: {생성 날짜}
```

---

## Section 3: Acceptance Criteria (ac.md) — Phase 2

### 목적

기술 용어 없이 기능의 평가 기준을 정의합니다. Solution에서 정의한 접근 방식이 실제로 사용자 문제를 해결했는지 검증하는 기준입니다.

### 작성 규칙

1. **비기술적 언어**: 개발자가 아닌 사람도 이해할 수 있도록 작성
   - ❌ "Redux state가 올바르게 업데이트된다"
   - ✅ "사용자가 설정을 변경하면 즉시 화면에 반영된다"

2. **사용자 관점**: 기능이 사용자에게 어떻게 보이고 동작하는지
   - ❌ "API 응답 시간이 200ms 이내"
   - ✅ "버튼을 클릭한 후 1초 내에 결과가 표시된다"

3. **독립적으로 테스트 가능**: 각 AC는 다른 기준 없이도 검증 가능
   - ❌ "사용자가 필터링할 수 있고 결과가 올바르다"
   - ✅ 두 개의 별도 기준으로 분리

4. **측정 가능성**: "빠르다" 대신 "3초 이내"처럼 구체적인 기준
   - ❌ "성능이 향상된다"
   - ✅ "페이지 로드 시간이 이전보다 50% 단축된다"

5. **분량**: 5~15개. 너무 적으면 불완전하고, 너무 많으면 오버스펙

### 템플릿

```markdown
# Acceptance Criteria: {프로젝트명}

## 기능 1: {기능명}

- [ ] AC 1: {검증 가능한 기준}
- [ ] AC 2: {검증 가능한 기준}
- [ ] AC 3: {검증 가능한 기준}

## 기능 2: {기능명}

- [ ] AC 1: {검증 가능한 기준}
- [ ] AC 2: {검증 가능한 기준}

---

**Sources**:
- Solution: {프로젝트명} Solution 섹션
- PRD: {Notion 링크}

*Generated*: {생성 날짜}
```

### 좋은 예시

```markdown
# Acceptance Criteria: 대량 캠페인 관리 도구

## 필터링

- [ ] 사용자가 예산 범위를 입력하면 해당 범위 내의 캠페인만 표시된다
- [ ] 상태 필터(활성/일시정지)를 선택하면 즉시 목록이 업데이트된다
- [ ] 필터 조건을 모두 제거하면 전체 캠페인이 다시 표시된다

## 일괄 작업

- [ ] 사용자가 최소 1개 이상의 캠페인을 선택할 수 있다
- [ ] 선택한 캠페인 개수가 우측 상단에 표시된다
- [ ] "일시정지" 버튼을 클릭하면 선택한 모든 캠페인이 일시정지된다
- [ ] 작업 완료 후 성공 메시지가 2초 동안 표시된다
```

---

## Section 4: Non-Functional Requirements (nfr.md) — Phase 2

### 목적

SLA/SLO 기반 비기능 요구사항을 정의합니다. 기능은 무엇을 하는가이고, NFR은 어떻게 해야 하는가입니다.

### 주요 카테고리

1. **성능 (Performance)**
   - 응답 시간: API 평균 응답 시간, 페이지 로드 시간
   - 처리량: 초당 요청 수(RPS), 동시 사용자 수
   - 메모리/CPU: 메모리 사용량, CPU 사용률

2. **신뢰성 (Reliability)**
   - 가용성: 99.9% uptime (SLA)
   - 에러율: 1% 미만의 API 에러율
   - 데이터 무결성: 트랜잭션 안정성

3. **확장성 (Scalability)**
   - 동시 사용자 확장: N명까지 성능 유지
   - 데이터 확장: 대용량 데이터 처리 능력

4. **보안 (Security)**
   - 데이터 암호화: 전송 중(TLS), 저장 중(AES-256)
   - 접근 제어: 권한 검증
   - 감시: 로그 기록 및 모니터링

5. **유지보수성 (Maintainability)**
   - 코드 품질: 테스트 커버리지 80% 이상
   - 문서화: API 문서, 구조 설계 문서

### 작성 규칙

1. **측정 가능한 메트릭**: "빠르다" 대신 "500ms 이내"
2. **현실적인 기준**: 기존 시스템의 성능 벤치마크 참고
3. **비즈니스 영향 고려**: 비용 vs 성능 트레이드오프 명시

### 템플릿

```markdown
# Non-Functional Requirements: {프로젝트명}

## 성능 (Performance)

- **API 응답 시간**: 평균 500ms, P99 1s 이내
- **페이지 로드 시간**: 3s 이내 (3G 모의 환경 기준)
- **동시 요청 처리**: 최소 1000 RPS

## 신뢰성 (Reliability)

- **가용성**: 99.9% (월 44분 이하 다운타임)
- **에러율**: 0.1% 미만
- **데이터 손실율**: 0%

## 보안 (Security)

- **데이터 암호화**: HTTPS TLS 1.2 이상
- **저장된 데이터**: AES-256 암호화
- **접근 제어**: 사용자 권한 검증 필수

## 확장성 (Scalability)

- **동시 사용자**: 10,000명 이상 지원
- **데이터**: 100GB 이상 처리 능력

---

**Sources**:
- Solution: {프로젝트명} Solution 섹션
- PRD: {Notion 링크}

*Generated*: {생성 날짜}
```

---

## Section 5: Functional Requirements (test-cases.md) — Phase 3

### 목적

Acceptance Criteria를 실행 가능한 Given/When/Then 테스트 케이스로 전환합니다. FE 관점에서 사용자 인터랙션, UI 상태 전환, 컴포넌트 동작을 검증할 수 있는 명세를 작성합니다.

### FE 테스트 케이스 구조

FE는 백엔드 Event Sourcing이 아닌 **UI 중심 패턴**을 따릅니다:

```
UI Component → User Interaction → State Change + Visual Feedback
```

#### 핵심 요소

1. **Entity/Feature**: AC에서 추출한 도메인 엔티티와 UI 컴포넌트 매핑
2. **User Action**: 사용자 인터랙션 (클릭, 입력, 스크롤, 네비게이션)
3. **State Transition**: UI 상태 변경 (로딩, 성공, 에러)
4. **Visual Feedback**: 사용자에게 보이는 변화

### 작성 규칙

#### 1. Entity 및 Component 식별

AC 섹션 제목과 본문에서 도메인 엔티티를 추출합니다:

**AC Example**:
```
## 기능 1: 최적화 추천 컬럼 표시
- [ ] 전문가모드 캠페인 목록에 '광고 최적화 추천' 컬럼이 표시된다
```

**추출 결과**:
- Entities: Campaign(캠페인), Recommendation(추천), Dashboard(대시보드)
- Components: `CampaignList`, `RecommendationColumn`, `CampaignRow`

#### 2. Happy Path vs Edge Cases 분리

**Happy Path** (1 AC = 1 Test Case):
- AC 항목과 1:1 매핑 (추적성 확보)
- 주요 사용자 플로우에 집중

**Edge Cases** (Feature별 별도 섹션):
- 로딩 상태 (Loading)
- 에러 처리 (Error)
- 빈 데이터 (Empty State)
- 네트워크 실패 (Network Failure)

#### 3. Given/When/Then 작성 가이드

**Given (전제 조건)** — UI 초기 상태:
- ✅ "사용자가 전문가모드 대시보드에 있다"
- ✅ "10개의 캠페인이 로드되어 있다"
- ❌ "Redux store에 campaigns 배열이 있다"

**When (사용자 액션)** — 단일 인터랙션:
- ✅ "추천 컬럼의 아이템을 클릭한다"
- ✅ "필터 조건을 입력한다"
- ❌ "fetchCampaigns API가 호출된다" (시스템 내부 동작)

**Then (기대 결과)** — 사용자에게 보이는 변화:
- ✅ "추천 상세 패널이 표시된다"
- ✅ "성공 메시지가 2초 동안 표시된다"
- ❌ "state.recommendations가 업데이트된다"

#### 4. UI State Transition 명시

각 테스트 케이스에 UI 상태 흐름을 포함합니다:

```
Initial → Loading → Success
                 ↘ Error
```

#### 5. API Dependencies 명시

FE 테스트의 백엔드 의존성을 기록합니다:

```
**API Dependencies**:
- Endpoint: GET /api/campaigns/:id/recommendations
- Success: { recommendations: [...] }
- Error: { error: "..." }
```

### 템플릿

```markdown
# Test Cases: {프로젝트명}

## Overview
- **Total Test Cases**: {count}
- **Based on**: ac.md ({AC 개수}개 AC → {TC 개수}개 TC)

---

## Feature: {기능명}

### Entities
- **Primary**: {entity name}
- **Related**: {related entities}

### UI Components
- `ComponentName` - {설명}

### Happy Path Test Cases

#### TC-{feature-num}.{test-num}: {test name}
- **AC Reference**: AC {num} - {AC 전문}
- **Given**:
  - {UI 초기 상태}
  - {데이터 상태}
- **When**: {사용자 액션}
- **Then**:
  - {UI 변화 1}
  - {UI 변화 2}

**UI State Transitions**:
{상태 흐름}

**API Dependencies** (if any):
- Endpoint: {endpoint}

---

### Edge Cases

#### TC-{feature-num}.E{edge-num}: {edge case name}
- **Scenario**: {설명}
- **Given**: {엣지 조건}
- **When**: {액션}
- **Then**: {처리 방법}

---

## Non-Functional Test Scenarios

### Performance (from nfr.md)
- TC-P1: {성능 테스트}

### Accessibility
- TC-A1: Keyboard navigation
- TC-A2: Screen reader support

---

**Sources**:
- AC: {project-name} ac.md
- NFR: {project-name} nfr.md

*Generated*: {date}
```

### 좋은 예시 vs 나쁜 예시

✅ **좋은 예시** (FE UI 중심):
```markdown
#### TC-1.1: 캠페인 목록에 추천 상태 표시
- **AC Reference**: AC 2 - 각 캠페인 행에 추천 상태가 표시된다
- **Given**:
  - 사용자가 전문가모드 대시보드에 있다
  - 5개 캠페인 중 2개에 추천이 있다
- **When**: 캠페인 목록이 렌더링된다
- **Then**:
  - 추천이 있는 캠페인에 "추천 있음" 배지가 표시된다
  - 추천이 없는 캠페인은 "없음" 상태로 표시된다
  - 상태별로 색상이 다르게 표시된다 (녹색/회색)

**UI State Transitions**:
Loading → Data Fetched → Render List → Display Badges
```

❌ **나쁜 예시** (백엔드 Event Sourcing 스타일):
```markdown
#### TC-1: Campaign aggregate test
- **Given**: CampaignAggregate exists with id=123
- **When**: LoadRecommendationsCommand is dispatched
- **Then**: RecommendationsLoadedEvent is persisted to event store

(FE가 아닌 백엔드 로직. UI에서 사용자가 보는 것에 집중해야 함)
```

❌ **나쁜 예시** (너무 모호):
```markdown
#### TC-1: 목록 테스트
- **Given**: 시스템 작동 중
- **When**: 사용자가 뭔가 한다
- **Then**: 작동한다

(구체적이지 않아 테스트 불가)
```

### 흔한 실수와 해결책

| 문제 | 원인 | 해결 |
|------|------|------|
| TC가 너무 기술적이다 | 백엔드 로직을 테스트하려 함 | UI 중심으로: 사용자가 보는 것, 클릭하는 것에 집중 |
| Given/When/Then이 모호하다 | 구체성 부족 | 정확한 UI 상태, 액션, 결과를 명시 |
| AC와 TC 매핑이 불명확하다 | AC Reference 누락 | 모든 TC에 AC Reference 명시 |
| 상태 전환이 없다 | UI 흐름 미고려 | 로딩→성공/에러 패턴 추가 |
| Edge Cases가 Happy Path와 섞임 | 구조 미분리 | Happy Path / Edge Cases 섹션 분리 |
| Entity가 과도하게 많다 | AC 텍스트의 모든 명사를 Entity로 추출 | 핵심 도메인 엔티티만 선별 (3~5개) |

---

## Section 6: Design (design.md) — Phase 4

### 목적

도메인 설계 및 컴포넌트 설계를 포함합니다.

### 하위 구조

- (Optional) Context & Container Diagram
- Component & Code - Client: domain/module, entities, usecases, Components & States
- (Optional) Component & Code - Server

*Phase 4에서 상세 가이드 추가 예정*

---

## 흔한 실수와 해결책

| 문제 | 원인 | 해결 |
|------|------|------|
| Solution이 너무 길다 | 설계까지 포함하려고 함 | 3~10문장으로 제한. 설계는 Design 섹션에서 |
| Solution이 너무 모호하다 | 문제 정의와 접근 방식을 충분히 설명하지 않음 | "무엇을 해결하는가" + "어떻게 해결하는가"를 명확히 |
| 링크가 유효하지 않다 | 복사-붙여넣기 오류 | URL 직접 확인, 권한 확인 |
| 디렉토리 구조가 일치하지 않음 | {project-name}을 이슈 ID로 사용함 | Linear Project 이름 또는 약어 사용 (예: adsc, api-center) |
