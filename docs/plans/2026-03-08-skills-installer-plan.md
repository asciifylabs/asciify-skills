# Skills Installer Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Create a curl-installable script that downloads principle skills into Claude Code's skills directory (global or local), registers a session-start update-check hook, and notifies users when updates are available.

**Architecture:** A single `install-skills.sh` script handles install/update/uninstall by downloading skill files from GitHub raw URLs and managing a version file + hook script in `~/.claude/scripts/`. The update-check hook runs on session start with a 24-hour cache TTL.

**Tech Stack:** Bash, curl, jq (optional, with Python fallback for JSON merging)

---

### Task 1: Create the update-check hook script

**Files:**
- Create: `update-check.sh` (this is the source file in the repo; the installer will copy it to `~/.claude/scripts/agentic-principles-update-check.sh`)

**Step 1: Write update-check.sh**

```bash
#!/bin/bash
# Agentic Principles — update check (runs on Claude Code session start)
# Checks for updates at most once per 24 hours

set -euo pipefail

VERSION_FILE="${HOME}/.claude/scripts/.agentic-principles-version"
REPO="asciifylabs/agentic-principles"
CACHE_TTL=86400  # 24 hours in seconds

# Exit silently if no version file (not installed via installer)
if [[ ! -f "${VERSION_FILE}" ]]; then
  exit 0
fi

# Read version file
source "${VERSION_FILE}"

# Check cache TTL
now=$(date +%s)
elapsed=$(( now - ${LAST_CHECK:-0} ))
if [[ ${elapsed} -lt ${CACHE_TTL} ]]; then
  exit 0
fi

# Check remote SHA (timeout after 5 seconds)
remote_sha=$(git ls-remote --heads "https://github.com/${REPO}.git" refs/heads/main 2>/dev/null | awk '{print $1}' || true)

if [[ -z "${remote_sha}" ]]; then
  # Network unavailable — exit silently
  exit 0
fi

# Update last check timestamp regardless of result
sed -i "s/^LAST_CHECK=.*/LAST_CHECK=${now}/" "${VERSION_FILE}" 2>/dev/null || true

# Compare SHAs
if [[ "${remote_sha}" != "${SHA:-}" ]]; then
  echo "Agentic Principles update available (installed: ${SHA:0:7}, latest: ${remote_sha:0:7}). To update, run:"
  echo "  curl -sSL https://raw.githubusercontent.com/${REPO}/main/install-skills.sh | bash -s -- --update"
fi
```

**Step 2: Make executable and verify syntax**

Run: `chmod +x update-check.sh && bash -n update-check.sh`
Expected: No output (syntax OK).

**Step 3: Commit**

```bash
git add update-check.sh
git commit -m "feat: add update-check hook script for session-start notifications"
```

---

### Task 2: Create the installer script

**Files:**
- Create: `install-skills.sh`

**Step 1: Write install-skills.sh**

```bash
#!/bin/bash
# Agentic Principles — Skills Installer
# Usage: curl -sSL https://raw.githubusercontent.com/asciifylabs/agentic-principles/main/install-skills.sh | bash
#   Options: --global, --local, --update, --uninstall

set -euo pipefail

REPO="asciifylabs/agentic-principles"
BRANCH="main"
RAW_BASE="https://raw.githubusercontent.com/${REPO}/${BRANCH}"
SCRIPTS_DIR="${HOME}/.claude/scripts"
VERSION_FILE="${SCRIPTS_DIR}/.agentic-principles-version"
SETTINGS_FILE="${HOME}/.claude/settings.json"
HOOK_SCRIPT="${SCRIPTS_DIR}/agentic-principles-update-check.sh"

SKILL_FILES=(
  ai-principles.md
  ansible-principles.md
  go-principles.md
  kubernetes-principles.md
  nodejs-principles.md
  python-principles.md
  rust-principles.md
  security-principles.md
  shell-principles.md
  terraform-principles.md
)

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${NC} $*"; }
success() { echo -e "${GREEN}[OK]${NC} $*"; }
warning() { echo -e "${YELLOW}[WARN]${NC} $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

# Parse arguments
MODE=""
INSTALL_DIR=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --global)    MODE="global"; shift ;;
    --local)     MODE="local"; shift ;;
    --update)    MODE="update"; shift ;;
    --uninstall) MODE="uninstall"; shift ;;
    *)           error "Unknown option: $1. Usage: $0 [--global|--local|--update|--uninstall]" ;;
  esac
done

# Determine install directory
resolve_install_dir() {
  case "${MODE}" in
    global)
      INSTALL_DIR="${HOME}/.claude/skills/agentic-principles"
      ;;
    local)
      if [[ ! -d ".git" ]] && ! git rev-parse --is-inside-work-tree &>/dev/null; then
        error "Not inside a git repository. --local must be run from a project root."
      fi
      INSTALL_DIR=".claude/skills/agentic-principles"
      ;;
    update)
      if [[ -f "${VERSION_FILE}" ]]; then
        source "${VERSION_FILE}"
        INSTALL_DIR="${INSTALL_DIR:-${HOME}/.claude/skills/agentic-principles}"
      else
        error "No existing installation found. Run without --update to install first."
      fi
      ;;
    "")
      echo ""
      echo "Agentic Principles — Skills Installer"
      echo ""
      echo "Where would you like to install?"
      echo "  1) Global — all projects (~/.claude/skills/)"
      echo "  2) Local  — this project only (.claude/skills/)"
      echo ""
      read -p "Select [1/2]: " -r choice
      case "${choice}" in
        1) MODE="global"; INSTALL_DIR="${HOME}/.claude/skills/agentic-principles" ;;
        2) MODE="local"; INSTALL_DIR=".claude/skills/agentic-principles" ;;
        *) error "Invalid choice" ;;
      esac
      ;;
  esac
}

# Download a file from the repo
download_file() {
  local path="$1"
  local dest="$2"
  local url="${RAW_BASE}/${path}"

  if ! curl -sSfL "${url}" -o "${dest}" 2>/dev/null; then
    error "Failed to download ${url}"
  fi
}

# Get current remote SHA
get_remote_sha() {
  git ls-remote --heads "https://github.com/${REPO}.git" refs/heads/main 2>/dev/null | awk '{print $1}' || echo "unknown"
}

# Merge hook into settings.json
register_hook() {
  local hook_cmd="bash ${HOOK_SCRIPT}"

  mkdir -p "$(dirname "${SETTINGS_FILE}")"

  # Create settings file if it doesn't exist
  if [[ ! -f "${SETTINGS_FILE}" ]]; then
    echo '{}' > "${SETTINGS_FILE}"
  fi

  # Check if hook already registered
  if grep -q "agentic-principles-update-check" "${SETTINGS_FILE}" 2>/dev/null; then
    info "Update hook already registered"
    return
  fi

  # Merge hook into settings using jq if available, otherwise Python
  if command -v jq &>/dev/null; then
    local tmp
    tmp=$(mktemp)
    jq --arg cmd "${hook_cmd}" '
      .hooks //= {} |
      .hooks.SessionStart //= [] |
      .hooks.SessionStart += [{"type": "command", "command": $cmd}]
    ' "${SETTINGS_FILE}" > "${tmp}" && mv "${tmp}" "${SETTINGS_FILE}"
  elif command -v python3 &>/dev/null; then
    python3 -c "
import json, sys
with open('${SETTINGS_FILE}', 'r') as f:
    settings = json.load(f)
settings.setdefault('hooks', {}).setdefault('SessionStart', []).append({
    'type': 'command',
    'command': '${hook_cmd}'
})
with open('${SETTINGS_FILE}', 'w') as f:
    json.dump(settings, f, indent=2)
"
  else
    warning "Neither jq nor python3 found. Add this manually to ${SETTINGS_FILE}:"
    echo "  hooks.SessionStart: [{\"type\": \"command\", \"command\": \"${hook_cmd}\"}]"
  fi
}

# Remove hook from settings.json
unregister_hook() {
  if [[ ! -f "${SETTINGS_FILE}" ]]; then
    return
  fi

  if command -v jq &>/dev/null; then
    local tmp
    tmp=$(mktemp)
    jq '
      if .hooks?.SessionStart then
        .hooks.SessionStart |= map(select(.command | contains("agentic-principles") | not))
      else . end
    ' "${SETTINGS_FILE}" > "${tmp}" && mv "${tmp}" "${SETTINGS_FILE}"
  elif command -v python3 &>/dev/null; then
    python3 -c "
import json
with open('${SETTINGS_FILE}', 'r') as f:
    settings = json.load(f)
hooks = settings.get('hooks', {}).get('SessionStart', [])
settings['hooks']['SessionStart'] = [h for h in hooks if 'agentic-principles' not in h.get('command', '')]
with open('${SETTINGS_FILE}', 'w') as f:
    json.dump(settings, f, indent=2)
"
  else
    warning "Cannot auto-remove hook. Manually remove the agentic-principles entry from ${SETTINGS_FILE}"
  fi
}

# Install skills
do_install() {
  info "Installing skills to ${INSTALL_DIR}..."
  mkdir -p "${INSTALL_DIR}"

  for skill in "${SKILL_FILES[@]}"; do
    download_file "skills/${skill}" "${INSTALL_DIR}/${skill}"
    success "Installed ${skill}"
  done

  # Install update-check hook
  mkdir -p "${SCRIPTS_DIR}"
  download_file "update-check.sh" "${HOOK_SCRIPT}"
  chmod +x "${HOOK_SCRIPT}"
  success "Installed update-check hook"

  # Write version file
  local sha
  sha=$(get_remote_sha)
  cat > "${VERSION_FILE}" <<EOF
SHA=${sha}
LAST_CHECK=$(date +%s)
INSTALL_DIR=${INSTALL_DIR}
EOF
  success "Version metadata saved"

  # Register hook in settings
  register_hook
  success "Session-start hook registered"

  echo ""
  success "Agentic Principles skills installed!"
  info "Skills location: ${INSTALL_DIR}"
  info "Updates will be checked automatically on session start (once per day)"
}

# Update skills
do_update() {
  info "Updating skills in ${INSTALL_DIR}..."

  if [[ ! -d "${INSTALL_DIR}" ]]; then
    error "Install directory ${INSTALL_DIR} not found. Run without --update to install first."
  fi

  for skill in "${SKILL_FILES[@]}"; do
    download_file "skills/${skill}" "${INSTALL_DIR}/${skill}"
    success "Updated ${skill}"
  done

  # Update hook script
  mkdir -p "${SCRIPTS_DIR}"
  download_file "update-check.sh" "${HOOK_SCRIPT}"
  chmod +x "${HOOK_SCRIPT}"

  # Update version file
  local sha
  sha=$(get_remote_sha)
  cat > "${VERSION_FILE}" <<EOF
SHA=${sha}
LAST_CHECK=$(date +%s)
INSTALL_DIR=${INSTALL_DIR}
EOF

  echo ""
  success "Agentic Principles skills updated to ${sha:0:7}!"
}

# Uninstall
do_uninstall() {
  info "Uninstalling Agentic Principles..."

  # Read install dir from version file
  if [[ -f "${VERSION_FILE}" ]]; then
    source "${VERSION_FILE}"
  fi

  # Remove skills
  if [[ -n "${INSTALL_DIR:-}" ]] && [[ -d "${INSTALL_DIR}" ]]; then
    rm -rf "${INSTALL_DIR}"
    success "Removed skills from ${INSTALL_DIR}"
  fi

  # Remove hook script and version file
  rm -f "${HOOK_SCRIPT}" "${VERSION_FILE}"
  success "Removed update-check hook"

  # Unregister from settings
  unregister_hook
  success "Removed session-start hook registration"

  echo ""
  success "Agentic Principles uninstalled"
}

# Main
main() {
  resolve_install_dir

  case "${MODE}" in
    global|local) do_install ;;
    update)       do_update ;;
    uninstall)    do_uninstall ;;
    *)            error "Unknown mode: ${MODE}" ;;
  esac
}

main
```

**Step 2: Make executable and verify syntax**

Run: `chmod +x install-skills.sh && bash -n install-skills.sh`
Expected: No output (syntax OK).

**Step 3: Commit**

```bash
git add install-skills.sh
git commit -m "feat: add skills installer with global/local install and auto-update hook"
```

---

### Task 3: Test the installer end-to-end

**Step 1: Test global install**

Run: `bash install-skills.sh --global`
Expected: All 10 skills downloaded to `~/.claude/skills/agentic-principles/`, hook registered, version file created.

**Step 2: Verify installed files**

Run: `ls ~/.claude/skills/agentic-principles/ && cat ~/.claude/scripts/.agentic-principles-version && cat ~/.claude/settings.json | grep -A2 agentic-principles`
Expected: 10 `.md` files, version file with SHA/LAST_CHECK/INSTALL_DIR, hook entry in settings.

**Step 3: Test update**

Run: `bash install-skills.sh --update`
Expected: All skills re-downloaded, version file updated, "Updated!" message.

**Step 4: Test update-check hook**

Run: `bash ~/.claude/scripts/agentic-principles-update-check.sh`
Expected: Either silent (up to date) or update message.

**Step 5: Test uninstall**

Run: `bash install-skills.sh --uninstall`
Expected: Skills removed, hook script removed, hook unregistered from settings.

**Step 6: Verify clean uninstall**

Run: `test ! -d ~/.claude/skills/agentic-principles && test ! -f ~/.claude/scripts/agentic-principles-update-check.sh && echo "Clean" || echo "Stale files"`
Expected: "Clean"

**Step 7: Re-install for continued use**

Run: `bash install-skills.sh --global`
Expected: Clean install succeeds.

---

### Task 4: Update README and docs

**Files:**
- Modify: `README.md`

**Step 1: Add installation section to README**

Add to the Quick Start section of `README.md`:

```markdown
## Quick Start

Install the skills globally (all projects):

```bash
curl -sSL https://raw.githubusercontent.com/asciifylabs/agentic-principles/main/install-skills.sh | bash -s -- --global
```

Or install for a specific project only:

```bash
cd /path/to/your/project
curl -sSL https://raw.githubusercontent.com/asciifylabs/agentic-principles/main/install-skills.sh | bash -s -- --local
```

Updates are checked automatically once per day. When an update is available, Claude will notify you at the start of your session.

To update manually:

```bash
curl -sSL https://raw.githubusercontent.com/asciifylabs/agentic-principles/main/install-skills.sh | bash -s -- --update
```

To uninstall:

```bash
curl -sSL https://raw.githubusercontent.com/asciifylabs/agentic-principles/main/install-skills.sh | bash -s -- --uninstall
```
```

**Step 2: Commit**

```bash
git add README.md
git commit -m "docs: add curl install instructions to README"
```

---

### Task 5: Commit design doc

**Step 1: Commit the design and plan docs**

```bash
git add docs/plans/2026-03-08-skills-installer-design.md docs/plans/2026-03-08-skills-installer-plan.md
git commit -m "docs: add installer design and implementation plan"
```
