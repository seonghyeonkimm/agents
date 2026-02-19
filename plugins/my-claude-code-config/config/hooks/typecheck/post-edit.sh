#!/bin/bash
# PostToolUse hook: Type-check after Edit/Write on TypeScript files
# Catches TS errors early (e.g., React 19 useRef, missing imports) before build time

# Read tool input from stdin
INPUT=$(cat)

# Extract the file path
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

# Only check TypeScript/TSX files
case "$FILE_PATH" in
  *.ts|*.tsx)
    ;;
  *)
    exit 0
    ;;
esac

# Find the nearest tsconfig.json (project root)
DIR=$(dirname "$FILE_PATH")
while [ "$DIR" != "/" ]; do
  if [ -f "$DIR/tsconfig.json" ]; then
    break
  fi
  DIR=$(dirname "$DIR")
done

if [ ! -f "$DIR/tsconfig.json" ]; then
  exit 0
fi

cd "$DIR" || exit 0

# Detect package manager
if [ -f "pnpm-lock.yaml" ]; then
  PM="pnpm"
elif [ -f "yarn.lock" ]; then
  PM="yarn"
else
  PM="npx"
fi

# Run tsc with 30s timeout, incremental for speed
OUTPUT=$(timeout 30 $PM tsc --noEmit --pretty false 2>&1 | head -20)
EXIT_CODE=${PIPESTATUS[0]}

if [ $EXIT_CODE -ne 0 ] && [ -n "$OUTPUT" ]; then
  echo "TypeScript errors found after editing $FILE_PATH:" >&2
  echo "$OUTPUT" >&2
  echo "---" >&2
  echo "Fix these before continuing to avoid build failures." >&2
fi

exit 0
