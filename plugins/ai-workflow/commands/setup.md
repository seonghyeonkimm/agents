AI 워크플로우를 위한 프로젝트 설정 파일들을 생성합니다.

이 명령어는 다음 파일들을 생성합니다:
- `init.sh` - 프로젝트 상태 검증 + 개발 서버 실행 스크립트
- `feature-list.json` - 작업 목록 및 상태 관리
- `claude-progress.txt` - 작업 진행 로그

---

## 0. 기존 파일 확인

```bash
ls -la init.sh feature-list.json claude-progress.txt 2>&1
```

이미 존재하는 파일이 있으면 사용자에게 알리고 덮어쓸지 확인하세요.

---

## 1. init.sh 생성

`ai-workflow:create-init-sh` 스킬을 사용하여 생성합니다.

**핵심 단계:**
1. package.json 분석하여 패키지 매니저 감지
2. lint, typecheck, dev 스크립트 찾기
3. 템플릿에 맞게 init.sh 생성
4. 실행 권한 부여 (`chmod +x init.sh`)

스크립트를 찾을 수 없으면 사용자에게 질문하세요.

---

## 2. feature-list.json 생성

`ai-workflow:create-feature-list` 스킬을 사용하여 생성합니다.

**핵심 단계:**
1. README, TODO 파일에서 기존 작업 정보 수집
2. 작업 항목을 JSON 스키마에 맞게 변환
3. feature-list.json 생성

작업 목록을 파악할 수 없으면 사용자에게 질문하세요.

---

## 3. claude-progress.txt 생성

`ai-workflow:create-progress-log` 스킬을 사용하여 생성합니다.

**핵심 단계:**
1. 초기 로그 내용 생성 (프로젝트 설정 완료 기록)
2. claude-progress.txt 생성

---

## 4. 완료 보고

모든 파일 생성 후:

---

**AI 워크플로우 설정 완료**

생성된 파일:
- ✅ `init.sh` - 프로젝트 검증 + 개발 서버 실행 스크립트
- ✅ `feature-list.json` - 작업 목록 ({N}개 feature 등록)
- ✅ `claude-progress.txt` - 진행 로그 초기화

**init.sh 기능:**
- Lint: {lint_command}
- Typecheck: {typecheck_command}
- Dev Server: {dev_command}

**다음 단계:**
`/ai-workflow:initialize` 명령어를 실행하여 작업을 시작하세요.

---

## 주의사항

- 이미 파일이 존재하면 덮어쓰지 않고 사용자에게 확인 요청
- 프로젝트 정보가 불확실하면 추측하지 말고 사용자에게 질문
- 모든 파일은 프로젝트 루트에 생성
- 각 스킬의 상세 내용은 해당 스킬 문서 참조
