# FE TechSpec Template

Linear 문서 생성 시 `create_document`의 content 파라미터에 아래 구조를 채워서 전달한다.

---

## Summary

Linear, PRD, Figma 등 프로젝트에 대한 배경, 프로젝트 맥락에서 다루는 목적과 할 수 있는 최대한의 요점을 적어주세요.

- **PRD**: {PRD_URL}
- **Figma**: {FIGMA_URL}

## Solution

해결책에 대해서 간단하게 서술합니다.

## Acceptance Criteria

기능 동작 관련, 최소 기준을 작성해요.

1. ...

## Non-Functional Requirements (A/SEO)

SLA/SLO를 준수하며 시스템 요구사항을 정의해요.

## Functional Requirements (Test cases / Given, When, Then)

기능 요구사항을 Test cases (Given, When, Then) 형태로 정의해요.

- Command = Event = (User) + ReadModel
- 명확히 BusinessLogic (Entity), API interface 정의하기!

### Entity: {EntityName}

**Command**: {CommandName}

| # | Given | When | Then |
|---|-------|------|------|
| 1 | | | |

## Design

기술적인 디자인에 대한 내용을 작성해요.

## (Optional) Context & Container Diagram

## Component & Code - Client

## (Optional) Component & Code - Server
