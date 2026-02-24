# CLAUDE.md

## 개발 가이드라인

- 플러그인 파일 형식과 템플릿 → `claude-config-patterns` 스킬 참조
- `plugins/` 파일 추가·수정·삭제 시 `./plugins/my-claude-code-config/sync.sh diff`로 동기화 상태 검증 필수
- 새로운 파일 카테고리 도입 시 sync.sh에 discover/sync 로직 추가 필요
- 디렉토리 구조 변경 시 sync.sh의 경로 매핑 확인 필요
