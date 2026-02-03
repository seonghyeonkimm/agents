# FE TechSpec Template

Linear 문서 생성 시 `create_document`의 content 파라미터에 아래 구조를 채워서 전달한다.

---

## Summary

Linear, PRD, Figma 등 프로젝트에 대한 배경, 프로젝트 맥락에서 다루는 목적과 할 수 있는 최대한의 요점을 적어주세요.

- **PRD**: {PRD_URL}
- **Figma**: {FIGMA_URL}

## Solution

⚠️ 기술 용어 없이 비즈니스 관점에서 핵심 변경사항을 요약합니다.

### 핵심 변경사항

1. **{변경1}**: {설명}
2. **{변경2}**: {설명}
3. **{변경3}**: {설명}

## Acceptance Criteria

기능 동작 관련, 최소 기준을 작성해요. 측정 가능하고 검증 가능한 문장으로 작성.

1. {주어} 상태에서 {동작}하면 {결과}가 발생한다
2. ...

## Non-Functional Requirements (A/SEO)

SLA/SLO를 준수하며 시스템 요구사항을 정의해요. 해당 없으면 생략 가능.

## Functional Requirements (Test cases / Given, When, Then)

⚠️ Entity/Command 헤더 없이 테이블만 작성. 정상 → 에러 → 엣지 케이스 순서.

| # | Given | When | Then |
|---|-------|------|------|
| 1 | {초기 상태/조건} | {사용자 행동/이벤트} | {기대 결과} |

## Design

⚠️ 아래 순서로 구조화하여 작성.

### 1. Domain & Entity

핵심 도메인 객체와 속성 정의. 실제 코드 타입과 1:1 매칭.

| Entity | 속성 | 설명 |
|--------|------|------|
| {Entity명} | {속성1}, {속성2}, ... | {설명} |

### 2. Usecase

| Usecase | Input | Output |
|---------|-------|--------|
| {Usecase명} | {입력} | {출력} |

### 3. Component & States

컴포넌트 계층 + State 설계.

```
Page
├── Container
│   ├── Component1
│   └── Component2
```

### 4. Usecase-Component Integration

| Usecase | Component | 연결 방식 |
|---------|-----------|----------|
| {Usecase} | {Component} | {설명} |

## (Optional) Context & Container Diagram

## Component & Code - Client

- Test cases 기반으로 module, entity, usecase 추출
- 컴포넌트 분해, 파일 구조, Props 인터페이스.

## (Optional) Component & Code - Server

## Verification

⚠️ Integration Test 최우선.

### Integration Tests (필수)

| TC# | 테스트 명 | 검증 내용 |
|-----|----------|----------|
| TC1 | {테스트명} | {검증 내용} |

### Unit Tests (필요 시)

복잡한 파생 상태 로직만 대상.

### E2E Tests (필요 시)

전체 사용자 플로우 검증.
