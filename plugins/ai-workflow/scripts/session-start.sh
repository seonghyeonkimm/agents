#!/bin/bash

# AI Workflow SessionStart Hook
# 세션 시작 시 workflow-starter agent 실행을 안내하는 컨텍스트를 주입합니다.

# JSON 출력으로 additionalContext 제공
cat << 'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "🚀 AI Workflow가 활성화되어 있습니다.\n\n프로젝트 워크플로우를 시작하려면 `ai-workflow:workflow-starter` agent를 사용하세요.\n\n이 agent는 다음을 수행합니다:\n1. 프로젝트 초기화 (init.sh 실행, feature-list 로드)\n2. 다음 작업 선택\n3. 적합한 agent 추천\n\n시작하려면: Task tool에서 subagent_type=\"ai-workflow:workflow-starter\" 사용"
  }
}
EOF
