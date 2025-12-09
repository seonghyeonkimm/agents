---
name: create-spec-doc
description: Linear 이슈에 스펙 문서를 작성합니다. 완료 기준(Acceptance Criteria)과 검증 방법을 포함하여, 검증 통과 시에만 완료를 보고합니다.
---

# Spec 문서 생성 스킬

Linear 이슈에 상세 스펙 문서를 작성합니다.

**핵심 원칙:** 스펙에는 반드시 **완료 기준(Acceptance Criteria)**이 포함되어야 하며, 모든 검증이 통과해야만 완료로 보고합니다.

## 스펙 저장 방식

스펙 문서는 Linear에 저장합니다:

1. **간단한 스펙**: 이슈 description에 직접 작성
2. **상세한 스펙**: 이슈 코멘트로 추가

## 1. 이슈 정보 확인

먼저 대상 이슈의 현재 내용을 확인합니다:

```
mcp__linear__get_issue:
  id: {issue_id}
```

기존 description 내용을 확인하고, 스펙을 어디에 추가할지 결정합니다.

## 2. 스펙 문서 구조

### 필수 섹션

```markdown
## 개요
{feature_overview}

## 목적
{feature_purpose}

## 기능 요구사항
- [ ] {requirement_1}
- [ ] {requirement_2}
- [ ] {requirement_3}

## 사용자 시나리오

### 시나리오: {scenario_name}
1. {step_1}
2. {step_2}
3. {step_3}

**예상 결과:** {expected_result}

## 완료 기준 (Acceptance Criteria)

### 자동 검증
| 검증 항목 | 명령어 | 성공 조건 |
|----------|--------|----------|
| 테스트 | `{test_command}` | 모든 테스트 통과 |
| 타입체크 | `{typecheck_command}` | 오류 0개 |
| 린트 | `{lint_command}` | 오류 0개 |

### 기능 검증
- [ ] {verification_1}: {how_to_verify_1}
- [ ] {verification_2}: {how_to_verify_2}

### 완료 정의 (Definition of Done)
- [ ] 모든 자동 검증 통과
- [ ] 모든 기능 검증 완료
- [ ] 기존 기능 회귀 없음

---
⚠️ **완료 보고 규칙**: 위 모든 항목이 통과해야만 완료로 보고합니다.
검증 실패 시 실패 내용을 보고하고 수정 작업을 계속합니다.
```

### 선택 섹션 (필요시 추가)

```markdown
## 비기능 요구사항
- 성능: {performance_requirement}
- 보안: {security_requirement}

## 기술 설계

### 관련 파일
| 파일 | 설명 |
|------|------|
| {file_path} | {description} |

### 데이터 구조
{data_structure}

### API 설계
{api_design}

## 엣지 케이스
| 케이스 | 처리 방법 |
|--------|----------|
| {case_1} | {handling_1} |

## 테스트 계획
- [ ] {test_case_1}
- [ ] {test_case_2}

## 참고 자료
- {reference_1}
- {reference_2}
```

## 3. 스펙 작성 방법

### 방법 A: 이슈 Description 업데이트

기존 description에 스펙을 추가합니다:

```
mcp__linear__update_issue:
  id: {issue_id}
  description: |
    {existing_description}

    ---

    ## 상세 스펙

    {spec_content}
```

### 방법 B: 코멘트로 추가 (상세 스펙)

별도 코멘트로 상세 스펙을 추가합니다:

```
mcp__linear__create_comment:
  issueId: {issue_id}
  body: |
    ## 상세 스펙 문서

    {full_spec_content}
```

## 4. 스펙 작성 후 라벨 업데이트

스펙 작성이 완료되면 `spec-needed` 라벨을 제거합니다:

```
mcp__linear__update_issue:
  id: {issue_id}
  labels: ["ai-workflow"]  # spec-needed 제거
```

## 5. 작성 규칙

**필수 섹션:**
- 개요
- 목적
- 기능 요구사항 (체크박스 형태)
- 사용자 시나리오 (최소 1개)
- **완료 기준 (Acceptance Criteria)** ← 가장 중요!

**선택 섹션:**
- 비기능 요구사항
- 기술 설계
- 엣지 케이스
- 테스트 계획
- 참고 자료

**완료 기준 작성 원칙:**
- 자동 검증: 실행 가능한 명령어와 성공 조건 명시
- 기능 검증: 어떻게 확인하는지 구체적으로 작성
- 정량적 기준 우선: "잘 동작함" ❌ → "응답 시간 500ms 이내" ✅

**불확실한 부분:**
- `TBD` 또는 `TODO`로 표시
- 체크박스로 진행 상황 추적 가능

## 6. Sub-task 생성 (선택사항)

스펙에서 파악된 세부 작업을 sub-issue로 생성:

```
mcp__linear__create_issue:
  team: {teamKey}
  title: {subtask_title}
  parentId: {parent_issue_id}
  labels: ["ai-workflow"]
```

## 7. 작업 완료 시 검증 워크플로우

작업이 완료되었다고 생각되면, 스펙의 완료 기준에 따라 검증을 수행합니다.

### 검증 단계

**1단계: 자동 검증 실행**
```bash
# 스펙에 명시된 검증 명령어들을 순서대로 실행
{test_command}
{typecheck_command}
{lint_command}
```

**2단계: 기능 검증 수행**
- 스펙의 "기능 검증" 체크리스트를 하나씩 확인
- 각 항목의 검증 방법대로 테스트
- 브라우저/앱에서 직접 동작 확인

**3단계: 회귀 테스트**
- 기존 기능이 깨지지 않았는지 확인
- 관련 테스트 스위트 실행

### 검증 결과에 따른 행동

**모든 검증 통과 시:**
```
✅ 작업 완료
- 이슈: {issue_identifier}
- 검증 결과: 모든 항목 통과

**자동 검증:**
- 테스트: ✅ 통과 (XX개 테스트)
- 타입체크: ✅ 오류 0개
- 린트: ✅ 오류 0개

**기능 검증:**
- ✅ {verification_1}
- ✅ {verification_2}
```

**검증 실패 시:**
```
⚠️ 검증 실패 - 수정 진행 중
- 이슈: {issue_identifier}

**실패 항목:**
- ❌ {failed_verification}: {failure_reason}

**다음 작업:**
- {what_to_fix}
```

검증 실패 시 완료로 보고하지 않고, 문제를 수정한 후 다시 검증합니다.

---

## 출력

### 스펙 작성 완료 시:

```
✅ 스펙 문서 작성 완료
- 이슈: {issue_identifier}
- 작성 위치: {description / comment}
- 섹션: 개요, 목적, 요구사항, 시나리오, **완료 기준**
- 라벨 업데이트: spec-needed 제거됨

**완료 기준 요약:**
- 자동 검증: {n}개 항목
- 기능 검증: {m}개 항목
```

### 작업 완료 시:

작업 완료 보고는 **모든 검증이 통과한 경우에만** 합니다.
위의 "검증 워크플로우"를 따라 검증하고, 결과를 포함하여 보고합니다.

---

## 주의사항

- 기존 description 내용을 유지하면서 추가
- 체크박스를 활용하여 진행 상황 추적 가능하게
- 불확실한 부분은 TBD로 표시하고 나중에 보완
- 복잡한 기능은 sub-issue로 분할 권장
- **완료 기준 없는 스펙은 불완전한 스펙입니다**
- **검증 통과 전에는 절대 완료로 보고하지 않습니다**
