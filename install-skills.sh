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
import json
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
