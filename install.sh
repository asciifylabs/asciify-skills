#!/bin/bash
# Asciify Skills — Installer
# Usage:
#   curl -sSL https://raw.githubusercontent.com/asciifylabs/asciify-skills/main/install.sh | bash
#   Options: --global (default), --local, --uninstall

set -euo pipefail

REPO="asciifylabs/asciify-skills"
BRANCH="main"
RAW_BASE="https://raw.githubusercontent.com/${REPO}/${BRANCH}"

SKILL_NAMES=(
  ai-principles
  ansible-principles
  docker-principles
  git-principles
  go-principles
  kubernetes-principles
  nodejs-principles
  python-principles
  rust-principles
  security-principles
  shell-principles
  terraform-principles
)

# Command files — installed to commands/ directory for slash command registration
COMMAND_FILES=(
  asciify-skills-update.md
  asciify-skills-uninstall.md
  asciify-skills-help.md
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
COMMANDS_DIR=""

while [[ $# -gt 0 ]]; do
  case $1 in
    --global)    MODE="global"; shift ;;
    --local)     MODE="local"; shift ;;
    --uninstall) MODE="uninstall"; shift ;;
    *)           error "Unknown option: $1. Usage: $0 [--global|--local|--uninstall]" ;;
  esac
done

# Determine install directory
resolve_install_dir() {
  case "${MODE}" in
    global)
      INSTALL_DIR="${HOME}/.claude/skills/asciify-skills"
      COMMANDS_DIR="${HOME}/.claude/commands/asciify-skills"
      ;;
    local)
      if [[ ! -d ".git" ]] && ! git rev-parse --is-inside-work-tree &>/dev/null; then
        error "Not inside a git repository. --local must be run from a project root."
      fi
      INSTALL_DIR=".claude/skills/asciify-skills"
      COMMANDS_DIR=".claude/commands/asciify-skills"
      ;;
    "")
      echo ""
      echo "Asciify Skills — Installer"
      echo ""
      echo "Where would you like to install?"
      echo "  1) Global — all projects (~/.claude/skills/)"
      echo "  2) Local  — this project only (.claude/skills/)"
      echo ""
      read -p "Select [1/2]: " -r choice
      case "${choice}" in
        1) MODE="global"; INSTALL_DIR="${HOME}/.claude/skills/asciify-skills"; COMMANDS_DIR="${HOME}/.claude/commands/asciify-skills" ;;
        2) MODE="local"; INSTALL_DIR=".claude/skills/asciify-skills"; COMMANDS_DIR=".claude/commands/asciify-skills" ;;
        *) error "Invalid choice" ;;
      esac
      ;;
  esac
}

# Detect if running from a local copy of the repo
SCRIPT_DIR=""
if [[ -n "${BASH_SOURCE[0]:-}" ]] && [[ -f "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/skills/security-principles/SKILL.md" ]]; then
  SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

# Download a file from the repo (or copy from local source)
download_file() {
  local path="$1"
  local dest="$2"

  # Prefer local copy if running from the repo
  if [[ -n "${SCRIPT_DIR}" ]] && [[ -f "${SCRIPT_DIR}/${path}" ]]; then
    cp "${SCRIPT_DIR}/${path}" "${dest}"
    return 0
  fi

  local url="${RAW_BASE}/${path}"
  if ! curl -sSfL "${url}" -o "${dest}" 2>/dev/null; then
    error "Failed to download ${url}"
  fi
}

# Install skills
do_install() {
  info "Installing skills to ${INSTALL_DIR}..."
  mkdir -p "${INSTALL_DIR}"

  for skill in "${SKILL_NAMES[@]}"; do
    mkdir -p "${INSTALL_DIR}/${skill}"
    download_file "skills/${skill}/SKILL.md" "${INSTALL_DIR}/${skill}/SKILL.md"
    success "Installed ${skill}"
  done

  # Install version file
  download_file "skills/.version" "${INSTALL_DIR}/.version"

  # Install slash commands to commands/ directory
  info "Installing commands to ${COMMANDS_DIR}..."
  mkdir -p "${COMMANDS_DIR}"

  for cmd in "${COMMAND_FILES[@]}"; do
    # Strip the "asciify-skills-" prefix for the destination filename
    # e.g. asciify-skills-update.md -> update.md
    local dest_name="${cmd#asciify-skills-}"
    download_file "skills/${cmd}" "${COMMANDS_DIR}/${dest_name}"
    success "Installed command ${dest_name}"
  done

  echo ""
  success "Asciify Skills installed!"
  echo ""
  info "Skills location: ${INSTALL_DIR}"
  info "Commands location: ${COMMANDS_DIR}"
  info "Skills activate automatically based on the files you work with."
  echo ""
  info "Management commands (inside Claude Code):"
  info "  /asciify-skills:update      — update to the latest version"
  info "  /asciify-skills:uninstall   — remove asciify-skills"
  info "  /asciify-skills:help        — show status and help"
}

# Uninstall
do_uninstall() {
  info "Uninstalling Asciify Skills..."

  local found=false

  # Check global install
  local global_dir="${HOME}/.claude/skills/asciify-skills"
  local global_cmds="${HOME}/.claude/commands/asciify-skills"
  if [[ -d "${global_dir}" ]]; then
    rm -rf "${global_dir}"
    success "Removed global skills from ${global_dir}"
    found=true
  fi
  if [[ -d "${global_cmds}" ]]; then
    rm -rf "${global_cmds}"
    success "Removed global commands from ${global_cmds}"
    found=true
  fi

  # Check local install
  local local_dir=".claude/skills/asciify-skills"
  local local_cmds=".claude/commands/asciify-skills"
  if [[ -d "${local_dir}" ]]; then
    rm -rf "${local_dir}"
    success "Removed local skills from ${local_dir}"
    found=true
  fi
  if [[ -d "${local_cmds}" ]]; then
    rm -rf "${local_cmds}"
    success "Removed local commands from ${local_cmds}"
    found=true
  fi

  # Clean up legacy agentic-principles install if present
  local legacy_global="${HOME}/.claude/skills/agentic-principles"
  local legacy_local=".claude/skills/agentic-principles"
  local legacy_hook="${HOME}/.claude/scripts/agentic-principles-update-check.sh"
  local legacy_version="${HOME}/.claude/scripts/.agentic-principles-version"

  if [[ -d "${legacy_global}" ]]; then
    rm -rf "${legacy_global}"
    success "Removed legacy install from ${legacy_global}"
    found=true
  fi
  if [[ -d "${legacy_local}" ]]; then
    rm -rf "${legacy_local}"
    success "Removed legacy install from ${legacy_local}"
    found=true
  fi
  rm -f "${legacy_hook}" "${legacy_version}" 2>/dev/null || true

  if [[ "${found}" == false ]]; then
    info "No installation found — nothing to remove."
  else
    echo ""
    success "Asciify Skills uninstalled."
  fi
}

# Main
main() {
  resolve_install_dir

  case "${MODE}" in
    global|local) do_install ;;
    uninstall)    do_uninstall ;;
    *)            error "Unknown mode: ${MODE}" ;;
  esac
}

main
