---
name: fe-techspec
description: |
  FE TechSpec 문서 작성 템플릿과 패턴. Linear 프로젝트의 기술 명세서를 작성할 때 참조.
  Use when: TechSpec 작성, 기술 명세서 생성, Given/When/Then 테스트 케이스 정의,
  Acceptance Criteria 작성, Solution 설계 문서 작성 시 사용.
---

# FE TechSpec

**관련 스킬:** `domain-invariant-pattern` - 불변식 헬퍼 함수 설계 패턴

FE TechSpec은 프로젝트의 기술적 구현 방향을 정의하는 문서. PRD(요구사항)와 Figma(디자인)를 기반으로 Solution, Acceptance Criteria, Test Cases를 도출한다.

## 문서 구조

```
Summary → Solution → Acceptance Criteria → Non-Functional Requirements → Functional Requirements (Given/When/Then) → Design → Component & Code → Verification
```

전체 템플릿은 `references/template.md` 참조.

## 섹션별 작성 가이드

### Summary

프로젝트 배경과 맥락. PRD/Figma 링크 포함.

```markdown
## Summary

{프로젝트 배경 1-3문장}

- **PRD**: {Notion URL}
- **Figma**: {Figma URL}
```

### Solution

비즈니스 관점에서 핵심 변경사항을 요약. 기술 용어 없이 "무엇이 어떻게 바뀌는가"에 집중.

```markdown
## Solution

### 핵심 변경사항

1. **{변경1}**: {설명}
2. **{변경2}**: {설명}
3. **{변경3}**: {설명}
```

**작성 규칙:**
- ❌ 코드, API명, 타입명 사용 금지
- ✅ 사용자/광고주 관점에서 서술
- 3-5개 핵심 변경사항을 번호 매기기 형식으로 나열

### Acceptance Criteria

기능 동작의 최소 기준. 테스트 가능한 형태로 작성.

```markdown
## Acceptance Criteria

1. {주어} 상태에서 {동작}하면 {결과}가 발생한다
2. ...
```

- 측정 가능하고 검증 가능한 문장으로 작성
- "빠르게", "잘" 같은 모호한 표현 금지
- 핵심 유저 플로우별 1개 이상

### Non-Functional Requirements

SLA/SLO 기준의 시스템 요구사항.

카테고리:
- **Performance**: LCP < 2.5s, FID < 100ms, CLS < 0.1
- **Accessibility**: WCAG AA
- **SEO**: 메타 태그, OG 태그, 시맨틱 마크업

해당 프로젝트에 관련 없는 카테고리는 생략 가능.

### Functional Requirements (Given/When/Then)

테스트 케이스를 구조화된 테이블로 정의.

**핵심 개념:**
- 기능 요구사항을 Test cases (Given, When, Then) 형태로 정의해요.

```markdown
## Functional Requirements (Test cases / Given, When, Then)

| # | Given | When | Then |
|---|-------|------|------|
| 1 | {초기 상태/조건} | {사용자 행동/이벤트} | {기대 결과} |
| 2 | ... | ... | ... |
```

작성 팁:
- 정상 케이스 → 에러 케이스 → 엣지 케이스 순서
- Given은 상태, When은 행동, Then은 검증 가능한 결과
- ⚠️ Entity/Command 식별은 Design 섹션에서 수행, FR에는 테이블만 작성

### Design

테스트 케이스 기반으로 도메인 설계를 진행.

**작성 순서:**
1. **Domain & Entity**: 핵심 도메인 객체와 속성 정의
   - Entity는 실제 코드의 타입/인터페이스와 1:1 매칭
   - 속성(Property)을 별도 Entity로 분리하지 않음
2. **Invariant Helpers**: 불변식을 헬퍼 함수로 추출
   - Given에서 `is*` 함수 추출 (상태 조건)
   - When에서 `can*` 함수 추출 (가능 조건)
   - Then에서 `get*`, `should*` 함수 추출 (파생 값, 동작 조건)
   - `domain-invariant-pattern` 스킬 참조
3. **Usecase**: 주요 사용 시나리오 테이블 (Input → Output + 관련 헬퍼)
4. **Component & States**: 컴포넌트 계층 + State 설계
5. **Usecase-Component Integration**: 연결 지점 정의

**Entity 작성 가이드:**
- ✅ `AdGroup` Entity에 `biddingType`, `deliveryType` 속성 포함
- ❌ `BiddingType`, `DeliveryType`을 별도 Entity로 정의

**Invariant Helper 가이드:**
- ✅ 여러 곳에서 재사용되는 비즈니스 규칙 → 헬퍼 함수로 추출
- ❌ 한 번만 사용되는 단순 조건 → 인라인으로 유지
- 의존성 순서: is* → can*, get* → should*

### Component & Code - Client
- Test cases 기반으로 module, entity, usecase 추출
- 컴포넌트 분해, 파일 구조, Props 인터페이스.

### (Optional) Context & Container Diagram / Component & Code - Server

필요한 경우에만 작성.

### Verification

테스트 케이스 검증 전략.

**우선순위:**
1. **Integration Tests (필수)**: TC 기반 컴포넌트 통합 테스트
2. **Unit Tests (필요 시)**: 복잡한 파생 상태 로직만
3. **E2E Tests (필요 시)**: 전체 사용자 플로우 검증

**Integration Test 테이블 형식:**
| TC# | 테스트 명 | 검증 내용 |
|-----|----------|----------|
| TC1 | ... | ... |

## 흔한 실수와 해결책

| 문제 | 원인 | 해결 |
|------|------|------|
| AC가 모호함 | "빠르게", "잘" 같은 추상적 표현 | 측정 가능한 기준 사용 (예: "3초 이내") |
| Given/When/Then 불명확 | 상태/행동/결과 구분 없음 | Given=상태, When=행동, Then=검증 가능한 결과 |
| Test Case 누락 | 정상 케이스만 작성 | 에러/엣지 케이스 반드시 포함 |
| NFR 생략 | 선택사항이라 무시 | 공개 페이지면 SEO/A11y 필수 검토 |
| Solution에 코드 포함 | "기술적 해결책"으로 오해 | 비기술 요약으로 작성 |
| Entity 과다 분리 | 속성을 Entity로 오인 | 실제 코드 타입과 1:1 매칭 |
| UI 문구 가정 | Figma 미확인 | variants에서 실제 문구 추출 |
| FR에 Entity/Command 헤더 | 지침 오해 | Design에서만 사용, FR은 테이블만 |
| Verification 누락 | 선택사항으로 오인 | Integration Test 필수 |
| 불변식 누락 | Given/When/Then에서 조건만 보고 헬퍼 미추출 | `domain-invariant-pattern` 스킬 참조 |
| 헬퍼 함수 중복 | UI/API에서 같은 조건을 각각 구현 | 공통 invariants.ts에 Single Source of Truth |
| 의존성 순서 오류 | can* 함수가 다른 can* 함수 호출 | Layer 구조 준수 (is* → can* → should*) |
