플러그인 버전을 업데이트합니다.

이 명령어는 `.claude-plugin/marketplace.json`의 플러그인 버전을 semantic versioning에 따라 관리합니다.

---

## 1. 현재 버전 확인

```bash
cat .claude-plugin/marketplace.json
```

등록된 플러그인들의 현재 버전을 표시합니다:

---

**등록된 플러그인:**

| 플러그인 | 현재 버전 |
|---------|----------|
| {plugin_name} | `{version}` |

어떤 플러그인의 버전을 업데이트할까요?

---

## 2. 버전 타입 선택

사용자에게 버전 업데이트 타입을 확인합니다:

> 어떤 종류의 변경인가요?
>
> | 타입 | 설명 | 예시 |
> |------|------|------|
> | **major** | 호환되지 않는 API 변경 | 2.0.0 → 3.0.0 |
> | **minor** | 이전 버전과 호환되는 기능 추가 | 2.0.0 → 2.1.0 |
> | **patch** | 이전 버전과 호환되는 버그 수정 | 2.0.0 → 2.0.1 |
>
> **가이드:**
> - `major`: breaking changes, 기존 명령어/스킬 삭제, 필수 의존성 변경
> - `minor`: 새 명령어/스킬/agent 추가, 새 기능 추가
> - `patch`: 버그 수정, 문서 수정, 성능 개선

---

## 3. 변경사항 입력

> 이번 버전의 주요 변경사항을 알려주세요:

변경사항을 카테고리별로 정리합니다:
- **Added**: 새로 추가된 기능
- **Changed**: 기존 기능의 변경
- **Fixed**: 버그 수정
- **Removed**: 삭제된 기능
- **Breaking**: 호환되지 않는 변경 (major only)

---

## 4. 버전 계산 및 업데이트

새 버전을 계산합니다:

```
현재: {major}.{minor}.{patch}

major 선택 시: {major+1}.0.0
minor 선택 시: {major}.{minor+1}.0
patch 선택 시: {major}.{minor}.{patch+1}
```

`.claude-plugin/marketplace.json`의 해당 플러그인 `version` 필드를 업데이트합니다.

---

## 5. CHANGELOG.md 업데이트

`plugins/{plugin_name}/CHANGELOG.md` 파일을 업데이트합니다.

파일이 없으면 생성:

```markdown
# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [{new_version}] - {YYYY-MM-DD}

### Added
- {added_items}

### Changed
- {changed_items}

### Fixed
- {fixed_items}

### Removed
- {removed_items}
```

기존 파일이 있으면 `## [Unreleased]` 아래에 새 버전 섹션을 추가합니다.

---

## 6. 완료 보고

---

**버전 업데이트 완료**

**플러그인:** `{plugin_name}`

| 항목 | 값 |
|------|-----|
| 이전 버전 | `{old_version}` |
| 새 버전 | `{new_version}` |
| 업데이트 타입 | `{type}` |

**변경사항:**
{changelog_summary}

**업데이트된 파일:**
- `.claude-plugin/marketplace.json`
- `plugins/{plugin_name}/CHANGELOG.md`

**다음 단계:**
```bash
git add -A && git commit -m "chore({plugin_name}): bump version to {new_version}"
```

---

## 주의사항

- Semantic Versioning(semver) 규칙을 따릅니다
- Breaking changes는 반드시 major 버전을 올려야 합니다
- 각 플러그인은 독립적인 버전을 가집니다
- 커밋은 사용자 확인 후 수행합니다
