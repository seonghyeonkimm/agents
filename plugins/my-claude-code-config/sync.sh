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

# Files to sync: config (stored under config/ in repo)
CONFIG_FILES=(
  "settings.json"
  "statusline.sh"
)

# Helper: find all .md files under a directory, returning relative paths
find_md_files() {
  local dir="$1"
  [ -d "$dir" ] || return 0
  (cd "$dir" && find . -name "*.md" -type f | sed 's|^\./||' | sort)
}

# Helper: find skill directory names (dirs containing SKILL.md)
find_skills() {
  local base="$1"
  [ -d "$base" ] || return 0
  for d in "$base"/*/; do
    [ -d "$d" ] && [ -f "$d/SKILL.md" ] && basename "$d"
  done | sort
}

# Helper: list all files in a skill directory, returning relative paths (excluding .bak)
find_skill_files() {
  local skill_dir="$1"
  [ -d "$skill_dir" ] || return 0
  (cd "$skill_dir" && find . -type f ! -name "*.bak" | sed 's|^\./||' | sort)
}

# Helper: find all files under a directory recursively, returning relative paths (excluding .bak)
find_all_files() {
  local dir="$1"
  [ -d "$dir" ] || return 0
  (cd "$dir" && find . -type f ! -name "*.bak" | sed 's|^\./||' | sort)
}

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

  # Commands (auto-discover all .md files under commands/)
  local cmd_files
  cmd_files="$(find_md_files "$CLAUDE_HOME/commands")"
  # Clean repo commands dir to handle renames/deletions
  if [ -d "$SCRIPT_DIR/commands" ]; then
    rm -rf "$SCRIPT_DIR/commands"
  fi
  if [ -n "$cmd_files" ]; then
    while IFS= read -r file; do
      src="$CLAUDE_HOME/commands/$file"
      dst="$SCRIPT_DIR/commands/$file"
      mkdir -p "$(dirname "$dst")"
      cp "$src" "$dst"
      log_ok "commands/$file"
    done <<< "$cmd_files"
  fi

  # Skills (auto-discover directories containing SKILL.md)
  local skill_names
  skill_names="$(find_skills "$CLAUDE_HOME/skills")"
  # Clean repo skills dir to handle renames/deletions
  if [ -d "$SCRIPT_DIR/skills" ]; then
    rm -rf "$SCRIPT_DIR/skills"
  fi
  if [ -n "$skill_names" ]; then
    while IFS= read -r skill; do
      local skill_files
      skill_files="$(find_skill_files "$CLAUDE_HOME/skills/$skill")"
      if [ -n "$skill_files" ]; then
        while IFS= read -r file; do
          src="$CLAUDE_HOME/skills/$skill/$file"
          dst="$SCRIPT_DIR/skills/$skill/$file"
          mkdir -p "$(dirname "$dst")"
          cp "$src" "$dst"
        done <<< "$skill_files"
      fi
      log_ok "skills/$skill/"
    done <<< "$skill_names"
  fi

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

  # Hooks (auto-discover all files under hooks/)
  local hook_files
  hook_files="$(find_all_files "$CLAUDE_HOME/hooks")"
  if [ -d "$SCRIPT_DIR/config/hooks" ]; then
    rm -rf "$SCRIPT_DIR/config/hooks"
  fi
  if [ -n "$hook_files" ]; then
    while IFS= read -r file; do
      src="$CLAUDE_HOME/hooks/$file"
      dst="$SCRIPT_DIR/config/hooks/$file"
      mkdir -p "$(dirname "$dst")"
      cp "$src" "$dst"
      log_ok "config/hooks/$file"
    done <<< "$hook_files"
  fi

  # Rules (auto-discover .md files)
  if ls "$CLAUDE_HOME/rules/"*.md 1>/dev/null 2>&1; then
    for rule in "$CLAUDE_HOME/rules/"*.md; do
      name="$(basename "$rule")"
      mkdir -p "$SCRIPT_DIR/rules"
      cp "$rule" "$SCRIPT_DIR/rules/$name"
      log_ok "rules/$name"
    done
  fi

  # Agents (auto-discover .md files)
  if ls "$CLAUDE_HOME/agents/"*.md 1>/dev/null 2>&1; then
    mkdir -p "$SCRIPT_DIR/agents"
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

  # Ensure base directories exist
  mkdir -p "$CLAUDE_HOME/commands"
  mkdir -p "$CLAUDE_HOME/rules"
  mkdir -p "$CLAUDE_HOME/agents"
  mkdir -p "$CLAUDE_HOME/skills"
  mkdir -p "$CLAUDE_HOME/hooks"

  # Commands (auto-discover from repo)
  local cmd_files
  cmd_files="$(find_md_files "$SCRIPT_DIR/commands")"
  if [ -n "$cmd_files" ]; then
    while IFS= read -r file; do
      src="$SCRIPT_DIR/commands/$file"
      dst="$CLAUDE_HOME/commands/$file"
      mkdir -p "$(dirname "$dst")"
      if [ -f "$dst" ]; then
        cp "$dst" "${dst}.bak"
      fi
      cp "$src" "$dst"
      log_ok "commands/$file"
    done <<< "$cmd_files"
  fi

  # Skills (auto-discover from repo)
  local skill_names
  skill_names="$(find_skills "$SCRIPT_DIR/skills")"
  if [ -n "$skill_names" ]; then
    while IFS= read -r skill; do
      local skill_files
      skill_files="$(find_skill_files "$SCRIPT_DIR/skills/$skill")"
      if [ -n "$skill_files" ]; then
        while IFS= read -r file; do
          src="$SCRIPT_DIR/skills/$skill/$file"
          dst="$CLAUDE_HOME/skills/$skill/$file"
          mkdir -p "$(dirname "$dst")"
          if [ -f "$dst" ]; then
            cp "$dst" "${dst}.bak"
          fi
          cp "$src" "$dst"
        done <<< "$skill_files"
      fi
      log_ok "skills/$skill/"
    done <<< "$skill_names"
  fi

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

  # Hooks (auto-discover from repo)
  local hook_files
  hook_files="$(find_all_files "$SCRIPT_DIR/config/hooks")"
  if [ -n "$hook_files" ]; then
    while IFS= read -r file; do
      src="$SCRIPT_DIR/config/hooks/$file"
      dst="$CLAUDE_HOME/hooks/$file"
      mkdir -p "$(dirname "$dst")"
      if [ -f "$dst" ]; then
        cp "$dst" "${dst}.bak"
      fi
      cp "$src" "$dst"
      chmod +x "$dst"
      log_ok "hooks/$file"
    done <<< "$hook_files"
  fi

  # Make config scripts executable
  chmod +x "$CLAUDE_HOME/statusline.sh" 2>/dev/null || true

  # Rules (auto-discover from repo)
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

  # Agents (auto-discover from repo)
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

  # Commands (dynamic discovery from both sides)
  local all_cmds=()
  while IFS= read -r f; do [ -n "$f" ] && all_cmds+=("$f"); done < <(find_md_files "$CLAUDE_HOME/commands")
  while IFS= read -r f; do [ -n "$f" ] && all_cmds+=("$f"); done < <(find_md_files "$SCRIPT_DIR/commands")
  mapfile -t all_cmds < <(printf '%s\n' "${all_cmds[@]}" | sort -u)
  for file in "${all_cmds[@]}"; do
    local_file="$CLAUDE_HOME/commands/$file"
    repo_file="$SCRIPT_DIR/commands/$file"
    if [ ! -f "$local_file" ]; then
      log_diff "commands/$file: only in repo"
      has_diff=true
    elif [ ! -f "$repo_file" ]; then
      log_diff "commands/$file: only in local"
      has_diff=true
    elif ! diff -q "$local_file" "$repo_file" >/dev/null 2>&1; then
      log_diff "commands/$file: differs"
      diff --color=auto "$repo_file" "$local_file" 2>/dev/null || true
      echo ""
      has_diff=true
    else
      log_ok "commands/$file: in sync"
    fi
  done

  # Skills (dynamic discovery from both sides)
  local all_skills=()
  while IFS= read -r s; do [ -n "$s" ] && all_skills+=("$s"); done < <(find_skills "$CLAUDE_HOME/skills")
  while IFS= read -r s; do [ -n "$s" ] && all_skills+=("$s"); done < <(find_skills "$SCRIPT_DIR/skills")
  mapfile -t all_skills < <(printf '%s\n' "${all_skills[@]}" | sort -u)
  for skill in "${all_skills[@]}"; do
    local_dir="$CLAUDE_HOME/skills/$skill"
    repo_dir="$SCRIPT_DIR/skills/$skill"
    if [ ! -d "$local_dir" ]; then
      log_diff "skills/$skill/: only in repo"
      has_diff=true
    elif [ ! -d "$repo_dir" ]; then
      log_diff "skills/$skill/: only in local"
      has_diff=true
    else
      # Compare all files within the skill directory
      local skill_files=()
      while IFS= read -r f; do [ -n "$f" ] && skill_files+=("$f"); done < <(find_skill_files "$local_dir")
      while IFS= read -r f; do [ -n "$f" ] && skill_files+=("$f"); done < <(find_skill_files "$repo_dir")
      mapfile -t skill_files < <(printf '%s\n' "${skill_files[@]}" | sort -u)
      local skill_in_sync=true
      for file in "${skill_files[@]}"; do
        local_file="$local_dir/$file"
        repo_file="$repo_dir/$file"
        if [ ! -f "$local_file" ]; then
          log_diff "skills/$skill/$file: only in repo"
          has_diff=true; skill_in_sync=false
        elif [ ! -f "$repo_file" ]; then
          log_diff "skills/$skill/$file: only in local"
          has_diff=true; skill_in_sync=false
        elif ! diff -q "$local_file" "$repo_file" >/dev/null 2>&1; then
          log_diff "skills/$skill/$file: differs"
          diff --color=auto "$repo_file" "$local_file" 2>/dev/null || true
          echo ""
          has_diff=true; skill_in_sync=false
        fi
      done
      if [ "$skill_in_sync" = true ]; then
        log_ok "skills/$skill/: in sync"
      fi
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

  # Hooks (dynamic discovery from both sides)
  local all_hooks=()
  while IFS= read -r f; do [ -n "$f" ] && all_hooks+=("$f"); done < <(find_all_files "$CLAUDE_HOME/hooks")
  while IFS= read -r f; do [ -n "$f" ] && all_hooks+=("$f"); done < <(find_all_files "$SCRIPT_DIR/config/hooks")
  mapfile -t all_hooks < <(printf '%s\n' "${all_hooks[@]}" | sort -u)
  for file in "${all_hooks[@]}"; do
    local_file="$CLAUDE_HOME/hooks/$file"
    repo_file="$SCRIPT_DIR/config/hooks/$file"
    if [ ! -f "$local_file" ]; then
      log_diff "hooks/$file: only in repo"
      has_diff=true
    elif [ ! -f "$repo_file" ]; then
      log_diff "hooks/$file: only in local"
      has_diff=true
    elif ! diff -q "$local_file" "$repo_file" >/dev/null 2>&1; then
      log_diff "hooks/$file: differs"
      diff --color=auto "$repo_file" "$local_file" 2>/dev/null || true
      echo ""
      has_diff=true
    else
      log_ok "hooks/$file: in sync"
    fi
  done

  # Rules (dynamic discovery from both sides)
  local all_rules=()
  if ls "$CLAUDE_HOME/rules/"*.md 1>/dev/null 2>&1; then
    for f in "$CLAUDE_HOME/rules/"*.md; do all_rules+=("$(basename "$f")"); done
  fi
  if ls "$SCRIPT_DIR/rules/"*.md 1>/dev/null 2>&1; then
    for f in "$SCRIPT_DIR/rules/"*.md; do all_rules+=("$(basename "$f")"); done
  fi
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
