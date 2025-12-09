init.sh에서 실행한 프로세스들을 정리합니다.

`.ai-workflow/clear.sh`가 있으면 실행하고, 없으면 setup을 안내합니다.

---

## 1. 설정 파일 확인 및 clear.sh 실행

```bash
# clear.sh 존재 확인 및 실행
if [ ! -f ".ai-workflow/clear.sh" ]; then
    echo "⚠️ clear.sh가 없습니다. /ai-workflow:setup을 먼저 실행해주세요."
else
    bash .ai-workflow/clear.sh
fi
```

**참고:** clear.sh는 init.sh에서 저장한 PID 파일들을 확인하여 해당 프로세스들을 종료합니다.

---

## 2. 결과 보고

다음 형식으로 보고합니다:

---

**🧹 AI Workflow 정리 완료**

**종료된 프로세스:**
- Dev Server (PID: {pid}) - {종료됨/이미 종료됨/실패}

**정리된 파일:**
- /tmp/dev-server.pid
- /tmp/dev-server.log
- /tmp/lint-output.txt
- /tmp/typecheck-output.txt

---
