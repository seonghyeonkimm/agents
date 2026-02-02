---
name: fe-techspec
description: |
  FE TechSpec 문서 작성 템플릿과 패턴. Linear 프로젝트의 기술 명세서를 작성할 때 참조.
  Use when: TechSpec 작성, 기술 명세서 생성, Given/When/Then 테스트 케이스 정의,
  Acceptance Criteria 작성, Solution 설계 문서 작성 시 사용.
---

# FE TechSpec

FE TechSpec은 프로젝트의 기술적 구현 방향을 정의하는 문서. PRD(요구사항)와 Figma(디자인)를 기반으로 Solution, Acceptance Criteria, Test Cases를 도출한다.

## 문서 구조

```
Summary → Solution → Acceptance Criteria → Non-Functional Requirements → Functional Requirements (Given/When/Then) → Design → Component & Code
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

기술적 해결책을 간결하게 서술. "무엇을 어떻게 구현할 것인가"에 집중.

```markdown
## Solution

{해결책 2-4문단. 핵심 컴포넌트, 상태 관리, API 연동 방식 포함}
```

- 구체적 기술 스택과 아키텍처 선택 이유 포함
- 주요 데이터 흐름 설명

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

### Design

기술적 디자인. 컴포넌트 계층, 상태 관리, API 계약.

### Component & Code - Client
- Test cases 기반으로 module, entity, usecase 추출
- 컴포넌트 분해, 파일 구조, Props 인터페이스.

### (Optional) Context & Container Diagram / Component & Code - Server

필요한 경우에만 작성.

## 흔한 실수와 해결책

| 문제 | 원인 | 해결 |
|------|------|------|
| AC가 모호함 | "빠르게", "잘" 같은 추상적 표현 | 측정 가능한 기준 사용 (예: "3초 이내") |
| Given/When/Then 불명확 | 상태/행동/결과 구분 없음 | Given=상태, When=행동, Then=검증 가능한 결과 |
| Solution이 너무 추상적 | 기술 스택 미언급 | 구체적 라이브러리, 패턴, 데이터 흐름 포함 |
| Test Case 누락 | 정상 케이스만 작성 | 에러/엣지 케이스 반드시 포함 |
| NFR 생략 | 선택사항이라 무시 | 공개 페이지면 SEO/A11y 필수 검토 |
