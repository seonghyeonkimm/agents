---
name: create-spec-doc
description: Feature에 대한 spec 문서를 docs 폴더에 생성합니다. 요구사항, 시나리오, 기술 설계를 포함한 표준 형식을 제공합니다.
---

# Spec 문서 생성 스킬

Feature에 대한 상세 스펙 문서를 생성합니다.

## 템플릿 파일

- `templates/spec.md.template` - spec 문서 템플릿

## 1. 파일명 규칙

- 위치: `docs/` 폴더
- 형식: `spec-{feature-name}.md`
- 케밥 케이스 사용
- 예: `docs/spec-user-authentication.md`

## 2. 템플릿 플레이스홀더

### 기본 정보

| 플레이스홀더 | 설명 | 예시 |
|-------------|------|------|
| `{{FEATURE_NAME}}` | 기능 이름 | `사용자 인증` |
| `{{FEATURE_OVERVIEW}}` | 간단한 설명 | `JWT 기반 로그인 시스템` |
| `{{FEATURE_PURPOSE}}` | 기능의 목적 | `보안 강화 및 사용자 경험 개선` |
| `{{CURRENT_DATE}}` | 생성일 | `2024-12-07` |

### 요구사항

| 플레이스홀더 | 설명 |
|-------------|------|
| `{{FUNCTIONAL_REQ_N}}` | 기능 요구사항 |
| `{{NON_FUNCTIONAL_REQ_N}}` | 비기능 요구사항 |

### 시나리오

| 플레이스홀더 | 설명 |
|-------------|------|
| `{{SCENARIO_NAME}}` | 시나리오 이름 |
| `{{SCENARIO_STEP_N}}` | 시나리오 단계 |
| `{{EXPECTED_RESULT}}` | 예상 결과 |

### 기술 설계

| 플레이스홀더 | 설명 |
|-------------|------|
| `{{RELATED_FILE_N}}` | 관련 파일 경로 |
| `{{FILE_DESCRIPTION_N}}` | 파일 설명 |
| `{{DATA_STRUCTURE}}` | 데이터 구조 설명 |
| `{{API_DESIGN}}` | API 설계 설명 |

### 엣지 케이스 & 테스트

| 플레이스홀더 | 설명 |
|-------------|------|
| `{{EDGE_CASE_N}}` | 엣지 케이스 |
| `{{EDGE_HANDLING_N}}` | 처리 방법 |
| `{{TEST_CASE_N}}` | 테스트 케이스 |
| `{{REFERENCE_N}}` | 참고 자료 |

## 3. 작성 규칙

**필수 섹션:**
- 개요
- 목적
- 기능 요구사항
- 사용자 시나리오 (최소 1개)

**선택 섹션:**
- 비기능 요구사항
- 기술 설계
- 엣지 케이스
- 테스트 계획
- 참고 자료

**불확실한 부분:**
- `TBD` 또는 `TODO`로 표시
- 체크박스로 진행 상황 추적

## 4. 파일 생성 절차

1. `docs/` 폴더 존재 확인 (없으면 생성)
2. 파일명 결정 (`spec-{feature-name}.md`)
3. `templates/spec.md.template` 읽기
4. 플레이스홀더 치환
5. 파일 저장

```bash
mkdir -p docs
```

## 5. 기존 파일 처리

동일한 이름의 spec 파일이 존재하면:
- 덮어쓰지 않음
- 사용자에게 확인 요청
- 버전 붙이기 제안 (예: `spec-auth-v2.md`)

## 출력

생성 완료 시:

```
✅ Spec 문서 생성 완료
- 파일: docs/spec-{feature-name}.md
- 섹션: 개요, 목적, 요구사항, 시나리오, 기술 설계
```
