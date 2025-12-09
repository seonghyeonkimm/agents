---
name: create-init-sh
description: 프로젝트 초기화 스크립트(init.sh)를 생성합니다. lint/typecheck 상태 확인 및 개발 서버 실행을 자동화합니다.
---

# Init.sh 생성 스킬

프로젝트의 초기화 스크립트를 생성합니다. 이 스크립트는 `/ai-workflow:init` 명령어로 실행됩니다.

## init.sh의 역할

1. **프로젝트 상태 체크**: lint, typecheck 실행하여 코드 품질 확인
2. **개발 서버 실행**: 개발 서버를 백그라운드에서 시작
3. **서버 상태 확인**: 서버가 정상적으로 실행되었는지 검증
4. **Linear 연결 확인**: config.json에서 Linear 설정 읽기
5. **결과 보고**: 초기화 결과 출력

## 1. 프로젝트 분석

먼저 `package.json`을 분석하여 사용 가능한 스크립트를 확인합니다:

```bash
cat package.json 2>/dev/null | head -100
```

**확인할 스크립트:**
- Lint: `lint`, `eslint`, `biome check`
- Typecheck: `typecheck`, `type-check`, `tsc`, `types`
- Dev server: `dev`, `start`, `serve`

**패키지 매니저 확인:**
```bash
# yarn.lock 또는 pnpm-lock.yaml 또는 package-lock.json 확인
ls yarn.lock pnpm-lock.yaml package-lock.json bun.lockb 2>/dev/null | head -1
```

---

## 2. init.sh 생성

분석 결과를 바탕으로 `.ai-workflow/init.sh`를 생성합니다:

```bash
cat > .ai-workflow/init.sh << 'INIT_SCRIPT'
#!/bin/bash

# AI Workflow Init Script
# /ai-workflow:init 명령어로 실행됩니다.

set -e

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 결과 저장 변수
LINT_STATUS="skipped"
TYPECHECK_STATUS="skipped"
DEV_SERVER_STATUS="not_started"
ERRORS=()

# 패키지 매니저 감지
detect_package_manager() {
    if [ -f "bun.lockb" ]; then
        echo "bun"
    elif [ -f "pnpm-lock.yaml" ]; then
        echo "pnpm"
    elif [ -f "yarn.lock" ]; then
        echo "yarn"
    else
        echo "npm"
    fi
}

PM=$(detect_package_manager)

# 1. Lint 체크
run_lint() {
    echo "🔍 Lint 체크 중..."
    if {PM_RUN} lint > /tmp/lint-output.txt 2>&1; then
        LINT_STATUS="pass"
        echo -e "${GREEN}✓ Lint 통과${NC}"
    else
        LINT_STATUS="fail"
        ERRORS+=("Lint 오류 발견")
        echo -e "${RED}✗ Lint 실패${NC}"
        cat /tmp/lint-output.txt | tail -20
    fi
}

# 2. Typecheck
run_typecheck() {
    echo "📝 타입 체크 중..."
    if {PM_RUN} {TYPECHECK_CMD} > /tmp/typecheck-output.txt 2>&1; then
        TYPECHECK_STATUS="pass"
        echo -e "${GREEN}✓ 타입 체크 통과${NC}"
    else
        TYPECHECK_STATUS="fail"
        ERRORS+=("타입 오류 발견")
        echo -e "${RED}✗ 타입 체크 실패${NC}"
        cat /tmp/typecheck-output.txt | tail -20
    fi
}

# 3. 개발 서버 시작
start_dev_server() {
    echo "🚀 개발 서버 시작 중..."

    # 이미 실행 중인 서버 확인
    if lsof -i:{DEV_PORT} > /dev/null 2>&1; then
        echo -e "${YELLOW}⚠ 포트 {DEV_PORT}에서 이미 서버가 실행 중입니다${NC}"
        DEV_SERVER_STATUS="already_running"
        return
    fi

    # 서버 시작 (백그라운드)
    nohup {PM_RUN} {DEV_CMD} > /tmp/dev-server.log 2>&1 &
    DEV_PID=$!
    echo $DEV_PID > /tmp/dev-server.pid

    # 서버 시작 대기 (최대 30초)
    echo "서버 시작 대기 중..."
    for i in {1..30}; do
        if curl -s http://localhost:{DEV_PORT} > /dev/null 2>&1; then
            DEV_SERVER_STATUS="running"
            echo -e "${GREEN}✓ 개발 서버 시작됨 (http://localhost:{DEV_PORT})${NC}"
            return
        fi
        sleep 1
    done

    DEV_SERVER_STATUS="failed"
    ERRORS+=("개발 서버 시작 실패")
    echo -e "${RED}✗ 개발 서버 시작 실패${NC}"
    cat /tmp/dev-server.log | tail -20
}

# 메인 실행
main() {
    echo "======================================"
    echo "🤖 AI Workflow 초기화"
    echo "======================================"
    echo ""

    # Lint 체크 (lint 스크립트가 있는 경우)
    if grep -q '"lint"' package.json 2>/dev/null; then
        run_lint
    else
        echo "ℹ️  Lint 스크립트 없음, 건너뜀"
    fi
    echo ""

    # Typecheck (typecheck 스크립트가 있는 경우)
    if grep -qE '"(typecheck|type-check|tsc)"' package.json 2>/dev/null; then
        run_typecheck
    else
        echo "ℹ️  Typecheck 스크립트 없음, 건너뜀"
    fi
    echo ""

    # 개발 서버 시작
    start_dev_server
    echo ""

    # 결과 요약
    echo "======================================"
    echo "📊 초기화 결과"
    echo "======================================"

    if [ ${#ERRORS[@]} -eq 0 ]; then
        OVERALL_STATUS="success"
    else
        OVERALL_STATUS="warning"
    fi

    # config.json에서 Linear 설정 읽기
    LINEAR_CONFIG=""
    if [ -f ".ai-workflow/config.json" ]; then
        TEAM_KEY=$(cat .ai-workflow/config.json | grep -o '"teamKey": "[^"]*"' | cut -d'"' -f4)
        LINEAR_CONFIG="Linear 연결됨: ${TEAM_KEY}"
    else
        LINEAR_CONFIG="Linear 미설정 (/ai-workflow:setup 필요)"
    fi

    # 결과 출력
    echo ""
    echo "- Lint: ${LINT_STATUS}"
    echo "- Typecheck: ${TYPECHECK_STATUS}"
    echo "- Dev Server: ${DEV_SERVER_STATUS} (http://localhost:{DEV_PORT})"
    echo "- ${LINEAR_CONFIG}"
    echo ""
}

main
INIT_SCRIPT
chmod +x .ai-workflow/init.sh
```

**위 템플릿에서 치환해야 할 값:**
- `{PM_RUN}`: 패키지 매니저 실행 명령 (`npm run`, `yarn`, `pnpm`, `bun run`)
- `{TYPECHECK_CMD}`: typecheck 스크립트 이름 (`typecheck`, `type-check`, `tsc`)
- `{DEV_CMD}`: 개발 서버 스크립트 이름 (`dev`, `start`)
- `{DEV_PORT}`: 개발 서버 포트 (기본값: 3000)

---

## 3. 스크립트 커스터마이징

사용자에게 확인할 사항:

---

**init.sh 설정 확인**

프로젝트 분석 결과:
- 패키지 매니저: `{detected_pm}`
- Lint 명령어: `{lint_cmd or "없음"}`
- Typecheck 명령어: `{typecheck_cmd or "없음"}`
- Dev 서버 명령어: `{dev_cmd}`
- Dev 서버 포트: `{port}`

이 설정으로 init.sh를 생성할까요? 수정이 필요하면 알려주세요.

---

## 4. 검증

생성된 스크립트 확인:

```bash
cat .ai-workflow/init.sh
```

실행 테스트:

```bash
bash .ai-workflow/init.sh
```

---

## 5. 완료 보고

---

**init.sh 생성 완료**

**생성된 파일:** `.ai-workflow/init.sh`

**설정된 체크:**
| 항목 | 명령어 |
|------|--------|
| Lint | `{pm} {lint_cmd}` |
| Typecheck | `{pm} {typecheck_cmd}` |
| Dev Server | `{pm} {dev_cmd}` |

**실행 방법:**
- `/ai-workflow:init` 명령어 실행
- 또는 수동 실행: `bash .ai-workflow/init.sh`

---

## 주의사항

- package.json의 scripts를 분석하여 명령어 감지
- 감지되지 않는 명령어는 사용자에게 확인
- 개발 서버 포트는 프로젝트 설정에 따라 다를 수 있음
- init.sh는 .ai-workflow 폴더에 저장되어 git에서 제외됨
