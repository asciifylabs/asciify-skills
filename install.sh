#!/bin/bash
# install.sh - Install coding principles hooks
# Usage: curl -sSL https://raw.githubusercontent.com/asciifylabs/agentic-principles/main/install.sh | bash

set -euo pipefail

# Configuration
REPO_BASE_URL="https://raw.githubusercontent.com/asciifylabs/agentic-principles/main"
HOOKS_DIR=".git/hooks"
INSTALL_DIR="$HOOKS_DIR"

# Detect if running from a local copy of the principles repo
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCAL_SOURCE=""
if [ -f "$SCRIPT_DIR/.claude/hooks/fetch-principles.sh" ]; then
  LOCAL_SOURCE="$SCRIPT_DIR"
elif [ -f "$SCRIPT_DIR/../.claude/hooks/fetch-principles.sh" ]; then
  LOCAL_SOURCE="$(cd "$SCRIPT_DIR/.." && pwd)"
fi

# Parse command line arguments
NON_INTERACTIVE=false
PRINCIPLES_ONLY=false
FORMATTING_ONLY=false
AUTO_INSTALL_TOOLS=false
UNINSTALL=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --non-interactive)
      NON_INTERACTIVE=true
      shift
      ;;
    --principles-only)
      PRINCIPLES_ONLY=true
      shift
      ;;
    --formatting-only)
      FORMATTING_ONLY=true
      shift
      ;;
    --auto-install-tools)
      AUTO_INSTALL_TOOLS=true
      shift
      ;;
    --uninstall)
      UNINSTALL=true
      shift
      ;;
    *)
      echo "Unknown option: $1"
      echo "Usage: $0 [--non-interactive] [--principles-only] [--formatting-only] [--auto-install-tools] [--uninstall]"
      exit 1
      ;;
  esac
done

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

info() {
  echo -e "${BLUE}[INFO]${NC} $*"
}

success() {
  echo -e "${GREEN}[SUCCESS]${NC} $*"
}

warning() {
  echo -e "${YELLOW}[WARNING]${NC} $*"
}

error() {
  echo -e "${RED}[ERROR]${NC} $*"
  exit 1
}

# Validation: Check if we're in a git repository
validate_git_repo() {
  if ! git rev-parse --is-inside-work-tree &>/dev/null; then
    error "Not a git repository. Please run this script from inside a git repository."
  fi
  info "Git repository detected"
}

# Validation: Check write permissions
validate_permissions() {
  if [ ! -d "$HOOKS_DIR" ]; then
    mkdir -p "$HOOKS_DIR" || error "Cannot create $HOOKS_DIR directory"
  fi

  if [ ! -w "$HOOKS_DIR" ]; then
    error "No write permission for $HOOKS_DIR"
  fi
  info "Write permissions verified"
}

# Install a file from local repo or download from GitHub
install_file() {
  local url_path=$1  # relative path like .claude/hooks/fetch-principles.sh
  local dest=$2

  # Prefer local copy if available
  if [ -n "$LOCAL_SOURCE" ] && [ -f "$LOCAL_SOURCE/$url_path" ]; then
    cp "$LOCAL_SOURCE/$url_path" "$dest"
    return 0
  fi

  # Fall back to downloading from GitHub
  local url="$REPO_BASE_URL/$url_path"
  if command -v curl &>/dev/null; then
    curl -sSL "$url" -o "$dest" || error "Failed to download $url"
  elif command -v wget &>/dev/null; then
    wget -q "$url" -O "$dest" || error "Failed to download $url"
  else
    error "Neither curl nor wget is available"
  fi
}

# Backup existing hook
backup_hook() {
  local hook_name=$1
  local hook_path="$HOOKS_DIR/$hook_name"

  if [ -f "$hook_path" ] && [ ! -f "$hook_path.backup-original" ]; then
    local timestamp=$(date +%Y%m%d-%H%M%S)
    cp "$hook_path" "$hook_path.backup-$timestamp"
    cp "$hook_path" "$hook_path.backup-original"
    info "Backed up existing $hook_name hook"
  fi
}

# Install principles hooks
install_principles() {
  info "Installing principles fetching hooks..."

  # Install fetch-principles.sh
  install_file ".claude/hooks/fetch-principles.sh" "$INSTALL_DIR/fetch-principles.sh"
  chmod +x "$INSTALL_DIR/fetch-principles.sh"
  success "Installed fetch-principles.sh"

  # Install post-checkout hook
  backup_hook "post-checkout"
  install_file ".claude/hooks/git-hooks/post-checkout" "$HOOKS_DIR/post-checkout"
  chmod +x "$HOOKS_DIR/post-checkout"
  success "Installed post-checkout hook"

  # Install post-merge hook
  backup_hook "post-merge"
  install_file ".claude/hooks/git-hooks/post-merge" "$HOOKS_DIR/post-merge"
  chmod +x "$HOOKS_DIR/post-merge"
  success "Installed post-merge hook"

  # Run fetch-principles.sh once
  info "Fetching principles for the first time..."
  bash "$INSTALL_DIR/fetch-principles.sh" || warning "Failed to fetch principles (you may need to run it manually)"
}

# Install formatting hooks
install_formatting() {
  info "Installing formatting/linting hooks..."

  # Install format-lint.sh
  install_file ".claude/hooks/format-lint.sh" "$INSTALL_DIR/format-lint.sh"
  chmod +x "$INSTALL_DIR/format-lint.sh"
  success "Installed format-lint.sh"

  # Install pre-commit hook
  backup_hook "pre-commit"
  install_file ".claude/hooks/git-hooks/pre-commit" "$HOOKS_DIR/pre-commit"
  chmod +x "$HOOKS_DIR/pre-commit"
  success "Installed pre-commit hook"

  # Check for formatting tools
  info "Checking for formatting tools..."
  local missing_tools=()

  # Shell
  command -v shellcheck &>/dev/null || missing_tools+=("shellcheck")
  command -v shfmt &>/dev/null || missing_tools+=("shfmt")
  # JS/TS/JSON/YAML/Markdown
  command -v prettier &>/dev/null || missing_tools+=("prettier")
  command -v eslint &>/dev/null || missing_tools+=("eslint")
  # Python
  command -v ruff &>/dev/null || missing_tools+=("ruff")
  # Go
  command -v gofmt &>/dev/null || missing_tools+=("gofmt")
  command -v golangci-lint &>/dev/null || missing_tools+=("golangci-lint")
  # Rust
  command -v rustfmt &>/dev/null || missing_tools+=("rustfmt")
  # Terraform
  command -v terraform &>/dev/null || missing_tools+=("terraform")
  command -v tflint &>/dev/null || missing_tools+=("tflint")
  # Ansible
  command -v ansible-lint &>/dev/null || missing_tools+=("ansible-lint")

  if [ ${#missing_tools[@]} -gt 0 ]; then
    warning "Missing formatting tools: ${missing_tools[*]}"
    echo ""
    echo "To install missing tools:"
    for tool in "${missing_tools[@]}"; do
      case $tool in
        shellcheck)
          echo "  apt install shellcheck  (or: brew install shellcheck)"
          ;;
        shfmt)
          echo "  brew install shfmt  (or: go install mvdan.cc/sh/v3/cmd/shfmt@latest)"
          ;;
        prettier)
          echo "  npm install -g prettier"
          ;;
        eslint)
          echo "  npm install -g eslint"
          ;;
        ruff)
          echo "  pip install ruff  (or: pipx install ruff)"
          ;;
        gofmt)
          echo "  Install Go from https://go.dev (gofmt is included)"
          ;;
        golangci-lint)
          echo "  go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest  (or: brew install golangci-lint)"
          ;;
        rustfmt)
          echo "  rustup component add rustfmt"
          ;;
        terraform)
          echo "  Install from https://developer.hashicorp.com/terraform/install"
          ;;
        tflint)
          echo "  brew install tflint  (or: curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash)"
          ;;
        ansible-lint)
          echo "  pip install ansible-lint  (or: pipx install ansible-lint)"
          ;;
      esac
    done
    echo ""

    warning "Only tools relevant to your project are needed. The pre-commit hook will skip files that require missing tools."
  else
    success "All formatting tools are installed"
  fi
}

# Show Claude Code instructions
show_claude_code_instructions() {
  echo ""
  info "To automatically load principles in Claude Code / AI agents:"
  echo ""
  echo "  Add a CLAUDE.md or AGENTS.md to your repo root with the initialization"
  echo "  script from this repository. See the project README for the full snippet."
  echo ""
  echo "  The init script will:"
  echo "    1. Clone/update the principles repo to /tmp/claude-principles-repo"
  echo "    2. Install git hooks (formatting, linting, principles auto-update)"
  echo "    3. Auto-detect technologies and load relevant principles"
  echo "    4. Merge Claude Code permissions into ~/.claude/settings.json"
  echo ""
  echo "  Hooks and principles auto-refresh on every git checkout, merge, and"
  echo "  Claude Code session start -- no manual updates needed."
  echo ""
  info "Set SKIP_SETTINGS=true to disable automatic settings sync."
  echo ""
}

# Uninstall hooks
uninstall_hooks() {
  info "Uninstalling hooks..."

  # Remove installed files
  local files=(
    "$INSTALL_DIR/fetch-principles.sh"
    "$INSTALL_DIR/format-lint.sh"
    "$HOOKS_DIR/post-checkout"
    "$HOOKS_DIR/post-merge"
    "$HOOKS_DIR/pre-commit"
  )

  for file in "${files[@]}"; do
    if [ -f "$file" ]; then
      # Restore backup if it exists
      if [ -f "$file.backup-original" ]; then
        mv "$file.backup-original" "$file"
        success "Restored original $file"
      else
        rm -f "$file"
        success "Removed $file"
      fi
    fi
  done

  # Clean up backup files
  find "$HOOKS_DIR" -name "*.backup-*" -type f -delete 2>/dev/null || true

  success "Uninstallation complete"
  exit 0
}

# Main installation flow
main() {
  echo ""
  echo "╔════════════════════════════════════════╗"
  echo "║  Coding Principles Hook Installer      ║"
  echo "╚════════════════════════════════════════╝"
  echo ""

  # Handle uninstall
  if [ "$UNINSTALL" = "true" ]; then
    validate_git_repo
    uninstall_hooks
  fi

  # Validation
  validate_git_repo
  validate_permissions

  # Determine installation mode
  INSTALL_PRINCIPLES=true
  INSTALL_FORMATTING=true

  if [ "$PRINCIPLES_ONLY" = "true" ]; then
    INSTALL_FORMATTING=false
  elif [ "$FORMATTING_ONLY" = "true" ]; then
    INSTALL_PRINCIPLES=false
  fi

  # Interactive mode: ask user what to install
  if [ "$NON_INTERACTIVE" = "false" ]; then
    echo "What would you like to install?"
    echo "  1) Full installation (principles + formatting) [default]"
    echo "  2) Principles only (auto-fetch coding standards)"
    echo "  3) Formatting only (pre-commit linting)"
    echo "  4) Uninstall"
    echo ""
    read -p "Select option [1-4]: " -r choice

    case $choice in
      2)
        INSTALL_FORMATTING=false
        ;;
      3)
        INSTALL_PRINCIPLES=false
        ;;
      4)
        uninstall_hooks
        ;;
      1|"")
        # Full installation (default)
        ;;
      *)
        error "Invalid choice"
        ;;
    esac
  fi

  echo ""

  # Install components
  if [ "$INSTALL_PRINCIPLES" = "true" ]; then
    install_principles
  fi

  if [ "$INSTALL_FORMATTING" = "true" ]; then
    install_formatting
  fi

  # Show Claude Code instructions if principles were installed
  if [ "$INSTALL_PRINCIPLES" = "true" ]; then
    show_claude_code_instructions
  fi

  # Success summary
  echo ""
  echo "╔════════════════════════════════════════╗"
  echo "║  Installation Complete!                ║"
  echo "╚════════════════════════════════════════╝"
  echo ""

  if [ "$INSTALL_PRINCIPLES" = "true" ]; then
    success "Principles will auto-update after git checkout/merge"
    info "Check /tmp/claude-principles-active.md for loaded principles"
  fi

  if [ "$INSTALL_FORMATTING" = "true" ]; then
    success "Code will auto-format before commits"
    info "Use 'git commit --no-verify' to skip formatting if needed"
  fi

  echo ""
  info "For troubleshooting, see: https://github.com/asciifylabs/agentic-principles/blob/main/docs/TROUBLESHOOTING.md"
  echo ""
}

main "$@"
