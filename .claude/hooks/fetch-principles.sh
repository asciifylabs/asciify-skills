#!/bin/bash
# fetch-principles.sh - Fetch and consolidate coding principles
# This script clones/updates the principles repository and generates
# a consolidated markdown file with relevant principles based on
# auto-detected technology categories.

set -euo pipefail

# Configuration with environment overrides
REPO_DIR="${PRINCIPLES_REPO_DIR:-/tmp/claude-principles-repo}"
OUTPUT="${PRINCIPLES_OUTPUT:-/tmp/claude-principles-active.md}"
REPO_SSH="git@github.com:asciifylabs/agentic-principles.git"
REPO_HTTPS="https://github.com/asciifylabs/agentic-principles.git"
LOCKFILE="/tmp/claude-principles.lock"
MAX_LOCK_AGE=30
VERBOSE="${VERBOSE:-false}"
CACHE_META="/tmp/claude-principles-cache.meta"
FORCE_REFRESH="${FORCE_REFRESH:-false}"

# Logging function
log() {
  if [ "$VERBOSE" = "true" ]; then
    echo "[fetch-principles] $*" >&2
  fi
}

error() {
  echo "[fetch-principles] ERROR: $*" >&2
}

# Cleanup function
cleanup() {
  if [ -f "$LOCKFILE" ]; then
    rm -f "$LOCKFILE"
    log "Removed lockfile"
  fi
}

trap cleanup EXIT

# Check and handle lockfile
if [ -f "$LOCKFILE" ]; then
  lock_age=$(($(date +%s) - $(stat -c %Y "$LOCKFILE" 2>/dev/null || stat -f %m "$LOCKFILE" 2>/dev/null || echo 0)))
  if [ "$lock_age" -lt "$MAX_LOCK_AGE" ]; then
    log "Another instance is running (lock age: ${lock_age}s), exiting"
    exit 0
  else
    log "Stale lock detected (age: ${lock_age}s), removing"
    rm -f "$LOCKFILE"
  fi
fi

# Create lockfile
echo $$ > "$LOCKFILE"
log "Created lockfile"

# --- Smart caching: skip fetch if remote main hasn't changed ---
if [ "$FORCE_REFRESH" != "true" ] && [ -d "$REPO_DIR/.git" ] && [ -f "$OUTPUT" ] && [ -f "$CACHE_META" ]; then
  LOCAL_SHA=$(git -C "$REPO_DIR" rev-parse HEAD 2>/dev/null || echo "")
  CONTEXT_KEY="$(pwd)|${EXTRA_CATEGORIES:-}"
  CACHED_CONTEXT=$(cat "$CACHE_META" 2>/dev/null || echo "")

  # Lightweight remote check — only queries ref, doesn't download objects
  REMOTE_SHA=$(git -C "$REPO_DIR" ls-remote origin refs/heads/main 2>/dev/null | cut -f1) || REMOTE_SHA=""

  if [ -n "$REMOTE_SHA" ] && [ "$REMOTE_SHA" = "$LOCAL_SHA" ] && [ "$CONTEXT_KEY" = "$CACHED_CONTEXT" ]; then
    log "Cache hit — remote unchanged (${LOCAL_SHA:0:8}), same project context"
    [ "$VERBOSE" = "false" ] && echo "Principles up to date (cached)"
    exit 0
  fi

  # Offline with matching context — use existing cache
  if [ -z "$REMOTE_SHA" ] && [ "$CONTEXT_KEY" = "$CACHED_CONTEXT" ]; then
    log "Offline — using cached principles"
    [ "$VERBOSE" = "false" ] && echo "Principles up to date (cached, offline)"
    exit 0
  fi
fi

# Clone or update repository
if [ -d "$REPO_DIR/.git" ]; then
  log "Updating existing repository at $REPO_DIR"
  if ! git -C "$REPO_DIR" pull --ff-only -q 2>/dev/null; then
    log "Pull failed, repository may be dirty or offline - using cached version"
  fi
else
  log "Cloning repository to $REPO_DIR"
  rm -rf "$REPO_DIR"
  if ! git clone --depth 1 -q "$REPO_SSH" "$REPO_DIR" 2>/dev/null; then
    log "SSH clone failed, trying HTTPS"
    if ! git clone --depth 1 -q "$REPO_HTTPS" "$REPO_DIR" 2>/dev/null; then
      error "Failed to clone principles repository"
      exit 1
    fi
  fi
  log "Repository cloned successfully"
fi

# Detect relevant categories from current directory
CATEGORIES=""

log "Detecting technology categories in $(pwd)"

# Shell: *.sh files
if find . -maxdepth 3 -name '*.sh' -print -quit 2>/dev/null | grep -q .; then
  CATEGORIES="$CATEGORIES shell"
  log "Detected: shell"
fi

# Terraform: *.tf files
if find . -maxdepth 3 -name '*.tf' -print -quit 2>/dev/null | grep -q .; then
  CATEGORIES="$CATEGORIES terraform"
  log "Detected: terraform"
fi

# Ansible: ansible.cfg, playbooks/, roles/
if [ -f ansible.cfg ] || [ -d playbooks ] || [ -d roles ]; then
  CATEGORIES="$CATEGORIES ansible"
  log "Detected: ansible"
fi

# Kubernetes: Chart.yaml, kustomization.yaml, or yaml with apiVersion
if [ -f Chart.yaml ] || [ -f kustomization.yaml ] || \
   find . -maxdepth 3 -name '*.yaml' -exec grep -l 'apiVersion:' {} + 2>/dev/null | head -1 | grep -q .; then
  CATEGORIES="$CATEGORIES kubernetes"
  log "Detected: kubernetes"
fi

# Node.js/TypeScript: package.json, *.js/*.jsx/*.ts/*.tsx files, or tsconfig.json
if [ -f package.json ] || [ -f tsconfig.json ] || find . -maxdepth 3 \( -name '*.js' -o -name '*.jsx' -o -name '*.ts' -o -name '*.tsx' \) -print -quit 2>/dev/null | grep -q .; then
  CATEGORIES="$CATEGORIES nodejs"
  log "Detected: nodejs"
fi

# Python: *.py files, requirements.txt, pyproject.toml, setup.py, or Pipfile
if [ -f requirements.txt ] || [ -f pyproject.toml ] || [ -f setup.py ] || [ -f Pipfile ] || \
   find . -maxdepth 3 -name '*.py' -print -quit 2>/dev/null | grep -q .; then
  CATEGORIES="$CATEGORIES python"
  log "Detected: python"
fi

# Go: go.mod, go.sum, or *.go files
if [ -f go.mod ] || [ -f go.sum ] || \
   find . -maxdepth 3 -name '*.go' -print -quit 2>/dev/null | grep -q .; then
  CATEGORIES="$CATEGORIES go"
  log "Detected: go"
fi

# Rust: Cargo.toml, Cargo.lock, or *.rs files
if [ -f Cargo.toml ] || [ -f Cargo.lock ] || \
   find . -maxdepth 3 -name '*.rs' -print -quit 2>/dev/null | grep -q .; then
  CATEGORIES="$CATEGORIES rust"
  log "Detected: rust"
fi

# AI: common AI/ML framework dependencies or imports
if [ -f pyproject.toml ] && grep -qiE 'openai|anthropic|langchain|llama.index|transformers|torch|tensorflow|keras|huggingface' pyproject.toml 2>/dev/null; then
  CATEGORIES="$CATEGORIES ai"
  log "Detected: ai"
elif [ -f requirements.txt ] && grep -qiE 'openai|anthropic|langchain|llama.index|transformers|torch|tensorflow' requirements.txt 2>/dev/null; then
  CATEGORIES="$CATEGORIES ai"
  log "Detected: ai"
elif [ -f package.json ] && grep -qiE '"openai"|"anthropic"|"@anthropic-ai"|"langchain"|"@langchain"' package.json 2>/dev/null; then
  CATEGORIES="$CATEGORIES ai"
  log "Detected: ai"
elif [ -f Cargo.toml ] && grep -qiE 'openai|anthropic|llm|candle' Cargo.toml 2>/dev/null; then
  CATEGORIES="$CATEGORIES ai"
  log "Detected: ai"
elif [ -f go.mod ] && grep -qiE 'openai|anthropic|langchain' go.mod 2>/dev/null; then
  CATEGORIES="$CATEGORIES ai"
  log "Detected: ai"
fi

# Security: always included (language-agnostic)
CATEGORIES="$CATEGORIES security"
log "Always included: security"

# Append any extra categories passed via env var
if [ -n "${EXTRA_CATEGORIES:-}" ]; then
  CATEGORIES="$CATEGORIES ${EXTRA_CATEGORIES}"
  log "Added extra categories: ${EXTRA_CATEGORIES}"
fi

# Fallback: if nothing detected, use all
if [ -z "$(echo "$CATEGORIES" | tr -d ' ')" ]; then
  CATEGORIES="shell ansible terraform kubernetes nodejs python go rust ai security"
  log "No categories detected, using all"
fi

# Trim leading/trailing spaces
CATEGORIES=$(echo "$CATEGORIES" | xargs)

log "Active categories: $CATEGORIES"

# Concatenate relevant principles into a single file
> "$OUTPUT"

for cat in $CATEGORIES; do
  dir="$REPO_DIR/$cat"
  if [ ! -d "$dir" ]; then
    log "Warning: Category directory not found: $dir"
    continue
  fi

  log "Processing category: $cat"
  echo "# ${cat^^} PRINCIPLES" >> "$OUTPUT"
  echo "" >> "$OUTPUT"

  for f in "$dir"/*.md; do
    if [ ! -f "$f" ]; then
      continue
    fi
    log "  Including: $(basename "$f")"
    cat "$f" >> "$OUTPUT"
    echo -e "\n---\n" >> "$OUTPUT"
  done
done

# Detect and include project ADRs (Architecture Decision Records)
ADR_DIRS=("docs/adr" "adr" "doc/adr" "docs/architecture/decisions" "docs/decisions")
ADR_FOUND=false

for adr_dir in "${ADR_DIRS[@]}"; do
  if [ -d "$adr_dir" ]; then
    adr_files=("$adr_dir"/*.md)
    # Check glob actually matched files
    if [ -f "${adr_files[0]}" ]; then
      ADR_FOUND=true
      log "Found ADRs in $adr_dir"
      echo "# PROJECT ADRs" >> "$OUTPUT"
      echo "" >> "$OUTPUT"
      for f in "${adr_files[@]}"; do
        log "  Including ADR: $(basename "$f")"
        cat "$f" >> "$OUTPUT"
        echo -e "\n---\n" >> "$OUTPUT"
      done
      break  # Only use the first matching ADR directory
    fi
  fi
done

if [ "$ADR_FOUND" = "false" ]; then
  log "No ADR directory found in project"
fi

# Output summary
line_count=$(wc -l < "$OUTPUT")
log "Generated $OUTPUT with $line_count lines"

# Merge Claude Code settings (permissions) into ~/.claude/settings.json
SETTINGS_SOURCE="$REPO_DIR/claude-settings.json"
SETTINGS_TARGET="$HOME/.claude/settings.json"
SKIP_SETTINGS="${SKIP_SETTINGS:-false}"

if [ "$SKIP_SETTINGS" = "true" ]; then
  log "Skipping settings merge (SKIP_SETTINGS=true)"
elif [ ! -f "$SETTINGS_SOURCE" ]; then
  log "No claude-settings.json found in principles repo, skipping settings merge"
else
  log "Merging Claude Code settings into $SETTINGS_TARGET"

  # Ensure ~/.claude directory exists
  mkdir -p "$HOME/.claude"

  # Initialize target if it doesn't exist or is empty
  if [ ! -f "$SETTINGS_TARGET" ] || [ ! -s "$SETTINGS_TARGET" ]; then
    echo '{}' > "$SETTINGS_TARGET"
  fi

  # Merge using jq (preferred) or python3 (fallback)
  if command -v jq &>/dev/null; then
    log "Using jq for settings merge"
    merged=$(jq -s '
      .[0] as $existing |
      .[1] as $new |
      $existing * {
        permissions: {
          allow: (
            (($existing.permissions // {}).allow // []) +
            (($new.permissions // {}).allow // [])
            | unique
          ),
          deny: (($existing.permissions // {}).deny // []),
          additionalDirectories: (
            (($existing.permissions // {}).additionalDirectories // []) +
            (($new.permissions // {}).additionalDirectories // [])
            | unique
          )
        }
      }
    ' "$SETTINGS_TARGET" "$SETTINGS_SOURCE") && echo "$merged" > "$SETTINGS_TARGET"
  elif command -v python3 &>/dev/null; then
    log "Using python3 for settings merge"
    python3 -c "
import json, sys

with open('$SETTINGS_TARGET') as f:
    existing = json.load(f)
with open('$SETTINGS_SOURCE') as f:
    new = json.load(f)

perms = existing.setdefault('permissions', {})

# Merge permissions.allow (union, preserving order)
existing_allow = perms.get('allow', [])
new_allow = new.get('permissions', {}).get('allow', [])
perms['allow'] = list(dict.fromkeys(existing_allow + new_allow))

# Merge permissions.additionalDirectories (union, preserving order)
existing_dirs = perms.get('additionalDirectories', [])
new_dirs = new.get('permissions', {}).get('additionalDirectories', [])
if existing_dirs or new_dirs:
    perms['additionalDirectories'] = list(dict.fromkeys(existing_dirs + new_dirs))

with open('$SETTINGS_TARGET', 'w') as f:
    json.dump(existing, f, indent=2)
    f.write('\n')
" && log "Settings merged successfully" || error "Failed to merge settings with python3"
  else
    error "Neither jq nor python3 available - cannot merge settings"
    log "Install jq or python3, or manually copy $SETTINGS_SOURCE to $SETTINGS_TARGET"
  fi
fi

# Refresh installed git hooks from the principles repo clone
# This ensures hooks stay up to date without re-running install.sh
if [ -d "$REPO_DIR/.claude/hooks" ] && git rev-parse --is-inside-work-tree &>/dev/null; then
  GIT_HOOKS_DIR="$(git rev-parse --git-dir)/hooks"
  if [ -d "$GIT_HOOKS_DIR" ]; then
    for hook_file in format-lint.sh fetch-principles.sh; do
      src="$REPO_DIR/.claude/hooks/$hook_file"
      dest="$GIT_HOOKS_DIR/$hook_file"
      if [ -f "$src" ] && [ -f "$dest" ]; then
        if ! cmp -s "$src" "$dest"; then
          cp "$src" "$dest"
          chmod +x "$dest"
          log "Updated $hook_file in git hooks"
        fi
      fi
    done
    for hook_file in pre-commit post-checkout post-merge; do
      src="$REPO_DIR/.claude/hooks/git-hooks/$hook_file"
      dest="$GIT_HOOKS_DIR/$hook_file"
      if [ -f "$src" ] && [ -f "$dest" ]; then
        if ! cmp -s "$src" "$dest"; then
          cp "$src" "$dest"
          chmod +x "$dest"
          log "Updated $hook_file git hook"
        fi
      fi
    done
  fi
fi

# Write cache metadata for next run
echo "$(pwd)|${EXTRA_CATEGORIES:-}" > "$CACHE_META"
log "Updated cache metadata"

if [ "$VERBOSE" = "false" ]; then
  echo "Loaded principles: $CATEGORIES"
fi
