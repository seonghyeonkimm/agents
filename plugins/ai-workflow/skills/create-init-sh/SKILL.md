---
name: create-init-sh
description: 프로젝트 상태 검증 및 개발 서버 실행을 위한 init.sh 스크립트를 생성합니다. lint, typecheck, dev server 명령어를 자동으로 감지합니다.
---

# init.sh 생성 스킬

프로젝트의 package.json을 분석하여 lint, typecheck, 개발 서버 실행 스크립트를 생성합니다.

## 템플릿 파일

- `templates/init.sh.template` - init.sh 스크립트 템플릿

## 1. 프로젝트 분석

```bash
# package.json 확인
cat package.json 2>/dev/null | head -80

# 패키지 매니저 확인
ls -la package-lock.json yarn.lock pnpm-lock.yaml bun.lockb 2>/dev/null
```

**수집할 정보:**
- 패키지 매니저: `npm` | `yarn` | `pnpm` | `bun`
- lint 스크립트 이름 및 존재 여부
- typecheck/tsc 스크립트 이름 및 존재 여부
- dev 서버 스크립트 이름 및 존재 여부

**패키지 매니저 감지 우선순위:**
1. `bun.lockb` → bun
2. `pnpm-lock.yaml` → pnpm
3. `yarn.lock` → yarn
4. `package-lock.json` → npm
5. 없으면 → npm (기본값)

## 2. 스크립트 매핑

**Lint 스크립트 (우선순위):**
1. `lint`
2. `eslint`
3. `lint:check`

**Typecheck 스크립트 (우선순위):**
1. `typecheck`
2. `type-check`
3. `tsc`
4. `types`
5. 없으면 → `tsc --noEmit` 직접 사용

**Dev 서버 스크립트 (우선순위):**
1. `dev`
2. `start:dev`
3. `serve`
4. `start`

## 3. 템플릿 사용

`templates/init.sh.template` 파일을 읽어서 플레이스홀더를 치환합니다.

**플레이스홀더:**
| 플레이스홀더 | 설명 | 예시 |
|-------------|------|------|
| `{{LINT_COMMAND}}` | lint 실행 명령어 | `pnpm lint` |
| `{{TYPECHECK_COMMAND}}` | typecheck 실행 명령어 | `pnpm typecheck` |
| `{{DEV_SERVER_COMMAND}}` | dev 서버 실행 명령어 | `pnpm dev` |

## 4. 불확실한 경우

스크립트를 찾을 수 없으면 사용자에게 질문:

> 프로젝트에서 사용하는 명령어를 알려주세요:
> - Lint 명령어: (예: `pnpm lint`)
> - Typecheck 명령어: (예: `pnpm typecheck`)
> - 개발 서버 명령어: (예: `pnpm dev`)

## 5. 파일 생성

```bash
# init.sh 생성 후 실행 권한 부여
chmod +x init.sh
```

## 6. 기존 파일 처리

`init.sh`가 이미 존재하면:
- 덮어쓰지 않고 사용자에게 확인 요청
- 기존 파일과 새 템플릿의 차이점 설명

## 출력

생성 완료 시:

```
✅ init.sh 생성 완료
- Lint: {lint_command}
- Typecheck: {typecheck_command}
- Dev Server: {dev_command}
```
