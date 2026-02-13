#!/bin/bash
# sync.sh - Bidirectional sync between ~/.claude and plugin repository
#
# Usage:
#   ./sync.sh export   # ~/.claude/ -> repo (capture local changes)
#   ./sync.sh import   # repo -> ~/.claude/ (apply repo settings)
#   ./sync.sh diff     # show differences between local and repo

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_HOME="${HOME}/.claude"

# Files to sync: plugin components
PLUGIN_FILES=(
  "commands/pr.md"
  "commands/pr-review.md"
  "commands/wrap.md"
  "commands/tdd/spec.md"
  "commands/tdd/design.md"
  "commands/tdd/issues.md"
  "commands/tdd/start.md"
  "commands/tdd/implement.md"
  "skills/claude-config-patterns/SKILL.md"
  "skills/code-dojo/SKILL.md"
  "skills/domain-invariant-pattern/SKILL.md"
  "skills/fe-techspec/SKILL.md"
  "skills/fe-techspec/references/template.md"
)

# Files to sync: config (stored under config/ in repo)
CONFIG_FILES=(
  "settings.json"
  "hooks/skill-activation-forced-eval.sh"
  "statusline.sh"
)

color_red='\033[31m'
color_green='\033[32m'
color_yellow='\033[33m'
color_cyan='\033[36m'
color_reset='\033[0m'

log_info() { printf "${color_cyan}[info]${color_reset} %s\n" "$1"; }
log_ok() { printf "${color_green}[ok]${color_reset} %s\n" "$1"; }
log_warn() { printf "${color_yellow}[warn]${color_reset} %s\n" "$1"; }
log_diff() { printf "${color_red}[diff]${color_reset} %s\n" "$1"; }

do_export() {
  log_info "Exporting ~/.claude settings to repo..."

  # Plugin components
  for file in "${PLUGIN_FILES[@]}"; do
    src="$CLAUDE_HOME/$file"
    dst="$SCRIPT_DIR/$file"
    if [ -f "$src" ]; then
      mkdir -p "$(dirname "$dst")"
      cp "$src" "$dst"
      log_ok "$file"
    else
      log_warn "Skip (not found): $src"
    fi
  done

  # Config files
  for file in "${CONFIG_FILES[@]}"; do
    src="$CLAUDE_HOME/$file"
    dst="$SCRIPT_DIR/config/$file"
    if [ -f "$src" ]; then
      mkdir -p "$(dirname "$dst")"
      cp "$src" "$dst"
      log_ok "config/$file"
    else
      log_warn "Skip (not found): $src"
    fi
  done

  # Copy any rule .md files
  if ls "$CLAUDE_HOME/rules/"*.md 1>/dev/null 2>&1; then
    for rule in "$CLAUDE_HOME/rules/"*.md; do
      name="$(basename "$rule")"
      mkdir -p "$SCRIPT_DIR/rules"
      cp "$rule" "$SCRIPT_DIR/rules/$name"
      log_ok "rules/$name"
    done
  fi

  # Copy any agent .md files
  if ls "$CLAUDE_HOME/agents/"*.md 1>/dev/null 2>&1; then
    for agent in "$CLAUDE_HOME/agents/"*.md; do
      name="$(basename "$agent")"
      cp "$agent" "$SCRIPT_DIR/agents/$name"
      log_ok "agents/$name"
    done
  fi

  echo ""
  log_info "Export complete. Review changes with: git diff"
}

do_import() {
  log_info "Importing repo settings to ~/.claude..."

  # Create directories
  mkdir -p "$CLAUDE_HOME/commands"
  mkdir -p "$CLAUDE_HOME/commands/tdd"
  mkdir -p "$CLAUDE_HOME/rules"
  mkdir -p "$CLAUDE_HOME/agents"
  mkdir -p "$CLAUDE_HOME/skills/claude-config-patterns"
  mkdir -p "$CLAUDE_HOME/skills/code-dojo"
  mkdir -p "$CLAUDE_HOME/skills/domain-invariant-pattern"
  mkdir -p "$CLAUDE_HOME/skills/fe-techspec/references"
  mkdir -p "$CLAUDE_HOME/hooks"

  # Plugin components
  for file in "${PLUGIN_FILES[@]}"; do
    src="$SCRIPT_DIR/$file"
    dst="$CLAUDE_HOME/$file"
    if [ -f "$src" ]; then
      if [ -f "$dst" ]; then
        cp "$dst" "${dst}.bak"
      fi
      cp "$src" "$dst"
      log_ok "$file"
    else
      log_warn "Skip (not in repo): $file"
    fi
  done

  # Config files with path substitution
  for file in "${CONFIG_FILES[@]}"; do
    src="$SCRIPT_DIR/config/$file"
    dst="$CLAUDE_HOME/$file"
    if [ -f "$src" ]; then
      if [ -f "$dst" ]; then
        cp "$dst" "${dst}.bak"
      fi
      mkdir -p "$(dirname "$dst")"
      # Replace hardcoded home paths with current user's home
      sed "s|/Users/[^/\"']*/\\.claude/|$CLAUDE_HOME/|g" "$src" > "$dst"
      log_ok "config/$file (path-adjusted)"
    else
      log_warn "Skip (not in repo): config/$file"
    fi
  done

  # Make scripts executable
  chmod +x "$CLAUDE_HOME/hooks/skill-activation-forced-eval.sh" 2>/dev/null || true
  chmod +x "$CLAUDE_HOME/statusline.sh" 2>/dev/null || true

  # Copy rule files
  if ls "$SCRIPT_DIR/rules/"*.md 1>/dev/null 2>&1; then
    for rule in "$SCRIPT_DIR/rules/"*.md; do
      name="$(basename "$rule")"
      dst="$CLAUDE_HOME/rules/$name"
      if [ -f "$dst" ]; then
        cp "$dst" "${dst}.bak"
      fi
      cp "$rule" "$dst"
      log_ok "rules/$name"
    done
  fi

  # Copy agent files
  if ls "$SCRIPT_DIR/agents/"*.md 1>/dev/null 2>&1; then
    for agent in "$SCRIPT_DIR/agents/"*.md; do
      name="$(basename "$agent")"
      dst="$CLAUDE_HOME/agents/$name"
      if [ -f "$dst" ]; then
        cp "$dst" "${dst}.bak"
      fi
      cp "$agent" "$dst"
      log_ok "agents/$name"
    done
  fi

  echo ""
  log_info "Import complete. Restart Claude Code to apply changes."
}

do_diff() {
  log_info "Comparing ~/.claude with repo..."
  has_diff=false

  # Plugin components
  for file in "${PLUGIN_FILES[@]}"; do
    local_file="$CLAUDE_HOME/$file"
    repo_file="$SCRIPT_DIR/$file"
    if [ ! -f "$local_file" ] && [ ! -f "$repo_file" ]; then
      continue
    elif [ ! -f "$local_file" ]; then
      log_diff "$file: only in repo"
      has_diff=true
    elif [ ! -f "$repo_file" ]; then
      log_diff "$file: only in local"
      has_diff=true
    elif ! diff -q "$local_file" "$repo_file" >/dev/null 2>&1; then
      log_diff "$file: differs"
      diff --color=auto "$repo_file" "$local_file" 2>/dev/null || true
      echo ""
      has_diff=true
    else
      log_ok "$file: in sync"
    fi
  done

  # Config files
  for file in "${CONFIG_FILES[@]}"; do
    local_file="$CLAUDE_HOME/$file"
    repo_file="$SCRIPT_DIR/config/$file"
    if [ ! -f "$local_file" ] && [ ! -f "$repo_file" ]; then
      continue
    elif [ ! -f "$local_file" ]; then
      log_diff "config/$file: only in repo"
      has_diff=true
    elif [ ! -f "$repo_file" ]; then
      log_diff "config/$file: only in local"
      has_diff=true
    elif ! diff -q "$local_file" "$repo_file" >/dev/null 2>&1; then
      log_diff "config/$file: differs"
      diff --color=auto "$repo_file" "$local_file" 2>/dev/null || true
      echo ""
      has_diff=true
    else
      log_ok "config/$file: in sync"
    fi
  done

  # Rules files (dynamic discovery)
  local all_rules=()
  if ls "$CLAUDE_HOME/rules/"*.md 1>/dev/null 2>&1; then
    for f in "$CLAUDE_HOME/rules/"*.md; do all_rules+=("$(basename "$f")"); done
  fi
  if ls "$SCRIPT_DIR/rules/"*.md 1>/dev/null 2>&1; then
    for f in "$SCRIPT_DIR/rules/"*.md; do all_rules+=("$(basename "$f")"); done
  fi
  # Deduplicate
  mapfile -t all_rules < <(printf '%s\n' "${all_rules[@]}" | sort -u)
  for name in "${all_rules[@]}"; do
    local_file="$CLAUDE_HOME/rules/$name"
    repo_file="$SCRIPT_DIR/rules/$name"
    if [ ! -f "$local_file" ]; then
      log_diff "rules/$name: only in repo"
      has_diff=true
    elif [ ! -f "$repo_file" ]; then
      log_diff "rules/$name: only in local"
      has_diff=true
    elif ! diff -q "$local_file" "$repo_file" >/dev/null 2>&1; then
      log_diff "rules/$name: differs"
      diff --color=auto "$repo_file" "$local_file" 2>/dev/null || true
      echo ""
      has_diff=true
    else
      log_ok "rules/$name: in sync"
    fi
  done

  echo ""
  if [ "$has_diff" = true ]; then
    log_warn "Some files differ. Use 'export' or 'import' to sync."
  else
    log_ok "All files are in sync."
  fi
}

case "${1:-}" in
  export)
    do_export
    ;;
  import)
    do_import
    ;;
  diff)
    do_diff
    ;;
  *)
    echo "Usage: $0 {export|import|diff}"
    echo ""
    echo "  export  Copy ~/.claude settings to this repo"
    echo "  import  Apply repo settings to ~/.claude (with backup)"
    echo "  diff    Show differences between local and repo"
    exit 1
    ;;
esac
