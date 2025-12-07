---
name: create-feature-list
description: 프로젝트의 작업 목록을 관리하는 feature-list.json 파일을 생성합니다. 기존 TODO나 이슈를 분석하여 초기 데이터를 구성합니다.
---

# feature-list.json 생성 스킬

프로젝트의 작업 목록과 상태를 관리하는 JSON 파일을 생성합니다.

## 템플릿 파일

- `templates/feature-list.json.template` - 전체 파일 템플릿
- `templates/feature-item.json.template` - 개별 feature 항목 템플릿

## 1. 기존 작업 정보 수집

```bash
# README 확인
cat README.md 2>/dev/null | head -100

# TODO 파일 확인
cat TODO.md TODO TODO.txt 2>/dev/null

# 이슈/태스크 관련 파일 확인
ls -la *.md docs/*.md 2>/dev/null
```

**찾을 정보:**
- README의 TODO 섹션
- 별도 TODO 파일
- 프로젝트 로드맵
- 기존 이슈 목록

## 2. 템플릿 사용

### feature-list.json.template 플레이스홀더

| 플레이스홀더 | 설명 | 예시 |
|-------------|------|------|
| `{{PROJECT_NAME}}` | 프로젝트 이름 | `my-app` |
| `{{CURRENT_DATE}}` | 현재 날짜 | `2024-12-07` |
| `{{FEATURE_TITLE}}` | 기능 제목 | `사용자 인증` |
| `{{FEATURE_DESCRIPTION}}` | 기능 설명 | `JWT 기반 로그인` |

### feature-item.json.template 플레이스홀더

| 플레이스홀더 | 설명 | 예시 |
|-------------|------|------|
| `{{FEATURE_ID}}` | 고유 식별자 | `feature-001` |
| `{{FEATURE_TITLE}}` | 기능 제목 | `사용자 인증` |
| `{{FEATURE_DESCRIPTION}}` | 기능 설명 | `JWT 기반 로그인` |
| `{{STATUS}}` | 작업 상태 | `pending` |
| `{{PRIORITY}}` | 우선순위 | `high` |
| `{{SPEC_PATH}}` | 스펙 문서 경로 | `docs/spec-auth.md` |
| `{{NOTES}}` | 추가 메모 | `보안 검토 필요` |

## 3. 필드 설명

| 필드 | 타입 | 설명 |
|------|------|------|
| `id` | string | 고유 식별자 (feature-001, ...) |
| `title` | string | 작업 제목 |
| `description` | string | 상세 설명 |
| `status` | enum | `pending` \| `in-progress` \| `completed` \| `blocked` |
| `priority` | enum | `high` \| `medium` \| `low` |
| `specPath` | string\|null | 스펙 문서 경로 |
| `relatedFiles` | string[] | 관련 파일 목록 |
| `notes` | string | 추가 메모 |

## 4. ID 생성 규칙

- 형식: `feature-{NNN}` (3자리 숫자)
- 순차적 증가: `feature-001`, `feature-002`, ...
- 기존 ID와 중복 불가

## 5. 자동 감지 패턴

README나 TODO에서 다음 패턴을 찾아 feature로 변환:

```markdown
- [ ] 작업1  →  status: pending
- [x] 작업2  →  status: completed
```

## 6. 불확실한 경우

작업 목록을 파악할 수 없으면:

> 현재 진행하려는 작업이나 기능이 있나요?
> 있다면 다음 정보를 알려주세요:
> - 작업 제목
> - 간단한 설명
> - 우선순위 (high/medium/low)

## 7. 기존 파일 처리

`feature-list.json`이 이미 존재하면:
- 덮어쓰지 않음
- 기존 파일 내용을 읽어 새 feature 추가 여부 확인
- 사용자에게 병합 또는 덮어쓰기 선택 요청

## 출력

생성 완료 시:

```
✅ feature-list.json 생성 완료
- 프로젝트: {project_name}
- 등록된 feature: {N}개
```
