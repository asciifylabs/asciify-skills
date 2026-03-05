#!/bin/bash
# format-lint.sh - Auto-format and lint staged files
# This script auto-detects file types and runs appropriate formatters/linters
# Supports both fix mode (auto-format) and check mode (CI/CD)

set -euo pipefail

# Configuration
MODE="${FORMAT_LINT_MODE:-fix}"  # fix or check
AUTO_INSTALL="${FORMAT_LINT_AUTO_INSTALL:-false}"
VERBOSE="${VERBOSE:-false}"
EXIT_CODE=0

# Logging functions
log() {
  if [ "$VERBOSE" = "true" ]; then
    echo "[format-lint] $*" >&2
  fi
}

info() {
  echo "[format-lint] $*" >&2
}

error() {
  echo "[format-lint] ERROR: $*" >&2
  EXIT_CODE=1
}

# Get files to check (staged files if in git repo, all files otherwise)
get_files_to_check() {
  if git rev-parse --is-inside-work-tree &>/dev/null; then
    git diff --cached --name-only --diff-filter=ACM 2>/dev/null || true
  else
    find . -type f -not -path '*/\.git/*' 2>/dev/null || true
  fi
}

# Check if a tool is installed, optionally install it
ensure_tool() {
  local tool=$1
  local install_cmd=$2

  if command -v "$tool" &>/dev/null; then
    log "Tool found: $tool"
    return 0
  fi

  log "Tool not found: $tool"

  if [ "$AUTO_INSTALL" = "true" ]; then
    info "Installing $tool..."
    if eval "$install_cmd" &>/dev/null; then
      info "Successfully installed $tool"
      return 0
    else
      error "Failed to install $tool"
      return 1
    fi
  else
    info "Tool $tool not found. To install: $install_cmd"
    info "Or run with FORMAT_LINT_AUTO_INSTALL=true to auto-install"
    return 1
  fi
}

# Format shell scripts
format_shell() {
  local files=("$@")
  [ ${#files[@]} -eq 0 ] && return 0

  log "Formatting ${#files[@]} shell script(s)"

  # Run shellcheck (linting)
  if ensure_tool shellcheck "npm install -g shellcheck || sudo apt-get install -y shellcheck || brew install shellcheck"; then
    for file in "${files[@]}"; do
      if ! shellcheck "$file" 2>/dev/null; then
        error "shellcheck found issues in $file"
      fi
    done
  fi

  # Run shfmt (formatting)
  if ensure_tool shfmt "npm install -g shfmt || GO111MODULE=on go install mvdan.cc/sh/v3/cmd/shfmt@latest || brew install shfmt"; then
    if [ "$MODE" = "fix" ]; then
      shfmt -i 2 -ci -bn -w "${files[@]}"
      log "Formatted shell scripts"
    else
      if ! shfmt -i 2 -ci -bn -d "${files[@]}" >/dev/null 2>&1; then
        error "Shell scripts need formatting"
      fi
    fi
  fi
}

# Format markdown files
format_markdown() {
  local files=("$@")
  [ ${#files[@]} -eq 0 ] && return 0

  log "Formatting ${#files[@]} markdown file(s)"

  if ensure_tool prettier "npm install -g prettier"; then
    if [ "$MODE" = "fix" ]; then
      prettier --write "${files[@]}" 2>/dev/null || true
      log "Formatted markdown files"
    else
      if ! prettier --check "${files[@]}" >/dev/null 2>&1; then
        error "Markdown files need formatting"
      fi
    fi
  fi
}

# Format JavaScript/TypeScript files
format_js() {
  local files=("$@")
  [ ${#files[@]} -eq 0 ] && return 0

  log "Formatting ${#files[@]} JavaScript/TypeScript file(s)"

  # Run prettier (formatting)
  if ensure_tool prettier "npm install -g prettier"; then
    if [ "$MODE" = "fix" ]; then
      prettier --write "${files[@]}" 2>/dev/null || true
      log "Formatted JS/TS files with prettier"
    else
      if ! prettier --check "${files[@]}" >/dev/null 2>&1; then
        error "JS/TS files need formatting"
      fi
    fi
  fi

  # Run eslint (linting)
  if ensure_tool eslint "npm install -g eslint"; then
    if [ "$MODE" = "fix" ]; then
      eslint --fix "${files[@]}" 2>/dev/null || true
      log "Linted JS/TS files with eslint"
    else
      if ! eslint "${files[@]}" >/dev/null 2>&1; then
        error "JS/TS files have linting issues"
      fi
    fi
  fi
}

# Format Python files
format_python() {
  local files=("$@")
  [ ${#files[@]} -eq 0 ] && return 0

  log "Formatting ${#files[@]} Python file(s)"

  # Run ruff (linting + formatting)
  if ensure_tool ruff "pip install ruff || pipx install ruff"; then
    if [ "$MODE" = "fix" ]; then
      ruff check --fix "${files[@]}" 2>/dev/null || true
      ruff format "${files[@]}" 2>/dev/null || true
      log "Formatted Python files with ruff"
    else
      if ! ruff check "${files[@]}" >/dev/null 2>&1; then
        error "Python files have linting issues"
      fi
      if ! ruff format --check "${files[@]}" >/dev/null 2>&1; then
        error "Python files need formatting"
      fi
    fi
  fi
}

# Format Go files
format_go() {
  local files=("$@")
  [ ${#files[@]} -eq 0 ] && return 0

  log "Formatting ${#files[@]} Go file(s)"

  # Run gofmt (formatting)
  if ensure_tool gofmt "echo 'gofmt is part of the Go toolchain - install Go from https://go.dev'"; then
    if [ "$MODE" = "fix" ]; then
      gofmt -w "${files[@]}"
      log "Formatted Go files with gofmt"
    else
      if [ -n "$(gofmt -l "${files[@]}" 2>/dev/null)" ]; then
        error "Go files need formatting"
      fi
    fi
  fi

  # Run golangci-lint (linting)
  if ensure_tool golangci-lint "go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest || brew install golangci-lint"; then
    if [ "$MODE" = "fix" ]; then
      golangci-lint run --fix "${files[@]}" 2>/dev/null || true
      log "Linted Go files with golangci-lint"
    else
      if ! golangci-lint run "${files[@]}" >/dev/null 2>&1; then
        error "Go files have linting issues"
      fi
    fi
  fi
}

# Format Rust files
format_rust() {
  local files=("$@")
  [ ${#files[@]} -eq 0 ] && return 0

  log "Formatting ${#files[@]} Rust file(s)"

  # Run rustfmt (formatting)
  if ensure_tool rustfmt "rustup component add rustfmt"; then
    if [ "$MODE" = "fix" ]; then
      rustfmt "${files[@]}" 2>/dev/null || true
      log "Formatted Rust files with rustfmt"
    else
      if ! rustfmt --check "${files[@]}" >/dev/null 2>&1; then
        error "Rust files need formatting"
      fi
    fi
  fi

  # Run clippy (linting) - only if in a cargo project
  if [ -f "Cargo.toml" ]; then
    if ensure_tool cargo "echo 'Install Rust from https://rustup.rs'"; then
      if [ "$MODE" = "fix" ]; then
        cargo clippy --fix --allow-dirty --allow-staged 2>/dev/null || true
        log "Linted Rust files with clippy"
      else
        if ! cargo clippy -- -D warnings >/dev/null 2>&1; then
          error "Rust files have clippy warnings"
        fi
      fi
    fi
  fi
}

# Format Terraform files
format_terraform() {
  local files=("$@")
  [ ${#files[@]} -eq 0 ] && return 0

  log "Formatting ${#files[@]} Terraform file(s)"

  if ensure_tool terraform "echo 'Install Terraform from https://developer.hashicorp.com/terraform/install'"; then
    if [ "$MODE" = "fix" ]; then
      for file in "${files[@]}"; do
        terraform fmt "$file" 2>/dev/null || true
      done
      log "Formatted Terraform files"
    else
      for file in "${files[@]}"; do
        if ! terraform fmt -check "$file" >/dev/null 2>&1; then
          error "Terraform file needs formatting: $file"
        fi
      done
    fi
  fi

  # Run tflint (linting)
  if ensure_tool tflint "brew install tflint || curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash"; then
    for file in "${files[@]}"; do
      local dir
      dir=$(dirname "$file")
      if ! tflint --chdir="$dir" 2>/dev/null; then
        error "Terraform linting issues in $file"
      fi
    done
  fi
}

# Format Ansible files
format_ansible() {
  local files=("$@")
  [ ${#files[@]} -eq 0 ] && return 0

  log "Linting ${#files[@]} Ansible file(s)"

  if ensure_tool ansible-lint "pip install ansible-lint || pipx install ansible-lint"; then
    for file in "${files[@]}"; do
      if ! ansible-lint "$file" 2>/dev/null; then
        error "Ansible linting issues in $file"
      fi
    done
  fi
}

# Format Kubernetes manifests (YAML with k8s content)
format_kubernetes() {
  local files=("$@")
  [ ${#files[@]} -eq 0 ] && return 0

  log "Linting ${#files[@]} Kubernetes manifest(s)"

  if ensure_tool kubeval "brew install kubeval || go install github.com/instrumenta/kubeval@latest"; then
    for file in "${files[@]}"; do
      if ! kubeval "$file" 2>/dev/null; then
        error "Kubernetes validation issues in $file"
      fi
    done
  fi
}

# Format JSON files
format_json() {
  local files=("$@")
  [ ${#files[@]} -eq 0 ] && return 0

  log "Formatting ${#files[@]} JSON file(s)"

  if ensure_tool prettier "npm install -g prettier"; then
    if [ "$MODE" = "fix" ]; then
      prettier --write "${files[@]}" 2>/dev/null || true
      log "Formatted JSON files"
    else
      if ! prettier --check "${files[@]}" >/dev/null 2>&1; then
        error "JSON files need formatting"
      fi
    fi
  fi
}

# Format YAML files
format_yaml() {
  local files=("$@")
  [ ${#files[@]} -eq 0 ] && return 0

  log "Formatting ${#files[@]} YAML file(s)"

  if ensure_tool prettier "npm install -g prettier"; then
    if [ "$MODE" = "fix" ]; then
      prettier --write "${files[@]}" 2>/dev/null || true
      log "Formatted YAML files"
    else
      if ! prettier --check "${files[@]}" >/dev/null 2>&1; then
        error "YAML files need formatting"
      fi
    fi
  fi
}

# Main execution
main() {
  log "Starting format-lint in $MODE mode"

  # Get all files to check
  local all_files
  mapfile -t all_files < <(get_files_to_check)

  if [ ${#all_files[@]} -eq 0 ]; then
    log "No files to check"
    exit 0
  fi

  log "Found ${#all_files[@]} file(s) to check"

  # Group files by type
  local shell_files=()
  local md_files=()
  local js_files=()
  local json_files=()
  local yaml_files=()
  local python_files=()
  local go_files=()
  local rust_files=()
  local terraform_files=()
  local ansible_files=()
  local kubernetes_files=()

  for file in "${all_files[@]}"; do
    # Skip if file doesn't exist (e.g., deleted files)
    [ -f "$file" ] || continue

    case "$file" in
      *.sh)
        shell_files+=("$file")
        ;;
      *.md)
        md_files+=("$file")
        ;;
      *.js|*.jsx|*.ts|*.tsx)
        js_files+=("$file")
        ;;
      *.json)
        json_files+=("$file")
        ;;
      *.py)
        python_files+=("$file")
        ;;
      *.go)
        go_files+=("$file")
        ;;
      *.rs)
        rust_files+=("$file")
        ;;
      *.tf|*.tfvars)
        terraform_files+=("$file")
        ;;
      *.yml|*.yaml)
        # Detect Ansible files (playbooks, roles, tasks)
        if grep -qlE '^\s*-\s+(hosts|tasks|roles|ansible\.builtin)\b' "$file" 2>/dev/null; then
          ansible_files+=("$file")
        # Detect Kubernetes manifests
        elif grep -qlE '^\s*apiVersion:\s' "$file" 2>/dev/null; then
          kubernetes_files+=("$file")
        fi
        yaml_files+=("$file")
        ;;
    esac
  done

  # Format each group
  [ ${#shell_files[@]} -gt 0 ] && format_shell "${shell_files[@]}"
  [ ${#md_files[@]} -gt 0 ] && format_markdown "${md_files[@]}"
  [ ${#js_files[@]} -gt 0 ] && format_js "${js_files[@]}"
  [ ${#json_files[@]} -gt 0 ] && format_json "${json_files[@]}"
  [ ${#yaml_files[@]} -gt 0 ] && format_yaml "${yaml_files[@]}"
  [ ${#python_files[@]} -gt 0 ] && format_python "${python_files[@]}"
  [ ${#go_files[@]} -gt 0 ] && format_go "${go_files[@]}"
  [ ${#rust_files[@]} -gt 0 ] && format_rust "${rust_files[@]}"
  [ ${#terraform_files[@]} -gt 0 ] && format_terraform "${terraform_files[@]}"
  [ ${#ansible_files[@]} -gt 0 ] && format_ansible "${ansible_files[@]}"
  [ ${#kubernetes_files[@]} -gt 0 ] && format_kubernetes "${kubernetes_files[@]}"

  # Re-stage formatted files if in fix mode and in git repo
  if [ "$MODE" = "fix" ] && git rev-parse --is-inside-work-tree &>/dev/null; then
    local modified_files
    mapfile -t modified_files < <(git diff --name-only -- "${all_files[@]}" 2>/dev/null || true)
    if [ ${#modified_files[@]} -gt 0 ]; then
      log "Re-staging ${#modified_files[@]} modified file(s)"
      git add -- "${modified_files[@]}"
    fi
  fi

  if [ $EXIT_CODE -eq 0 ]; then
    log "Format-lint completed successfully"
  else
    error "Format-lint found issues"
  fi

  exit $EXIT_CODE
}

main "$@"
