#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="${SCRIPT_DIR}/skills"
SKIP_DIRS="skills docs .claude .git"

mkdir -p "${SKILLS_DIR}"

# Trigger descriptions per category
declare -A TRIGGERS=(
  [security]="Use when writing, reviewing, or modifying any code in any language"
  [shell]="Use when writing, reviewing, or modifying shell scripts (.sh, .bash, Makefile, Dockerfile)"
  [go]="Use when writing, reviewing, or modifying Go code (.go, go.mod, go.sum)"
  [python]="Use when writing, reviewing, or modifying Python code (.py, pyproject.toml, requirements.txt)"
  [nodejs]="Use when writing, reviewing, or modifying JavaScript or TypeScript code (.js, .ts, .tsx, package.json)"
  [rust]="Use when writing, reviewing, or modifying Rust code (.rs, Cargo.toml)"
  [terraform]="Use when writing, reviewing, or modifying Terraform code (.tf, .tfvars)"
  [ansible]="Use when writing, reviewing, or modifying Ansible code (playbooks, roles, ansible.cfg)"
  [kubernetes]="Use when writing, reviewing, or modifying Kubernetes manifests or Helm charts"
  [ai]="Use when writing, reviewing, or modifying AI/ML code using frameworks like OpenAI, Anthropic, LangChain, PyTorch, TensorFlow"
  [git]="Use when creating git commits, writing commit messages, or performing any git operations"
)

# Generate linting section for a given category
generate_linting_section() {
  local category="$1"
  case "${category}" in
    shell)
      cat <<'LINT'

---

# Linting and Formatting

Before considering code complete, run the following tools on all changed files. If a tool is not installed, skip it and suggest the install command to the user.

- **shellcheck** — static analysis for shell scripts: `shellcheck script.sh`
- **shfmt** — format shell scripts consistently: `shfmt -w script.sh`

Auto-fix what can be auto-fixed. Report unfixable issues to the user.
LINT
      ;;
    go)
      cat <<'LINT'

---

# Linting and Formatting

Before considering code complete, run the following tools on all changed files. If a tool is not installed, skip it and suggest the install command to the user.

- **gofmt** — format Go source files: `gofmt -w .`
- **go vet** — report likely mistakes in Go code: `go vet ./...`
- **golangci-lint** — comprehensive Go linter aggregator: `golangci-lint run ./...`

Auto-fix what can be auto-fixed. Report unfixable issues to the user.
LINT
      ;;
    python)
      cat <<'LINT'

---

# Linting and Formatting

Before considering code complete, run the following tools on all changed files. If a tool is not installed, skip it and suggest the install command to the user.

- **ruff** — fast Python linter and formatter, lint with auto-fix: `ruff check --fix .`
- **ruff** — format Python files: `ruff format .`

Auto-fix what can be auto-fixed. Report unfixable issues to the user.
LINT
      ;;
    nodejs)
      cat <<'LINT'

---

# Linting and Formatting

Before considering code complete, run the following tools on all changed files. If a tool is not installed, skip it and suggest the install command to the user.

- **eslint** — lint JavaScript and TypeScript files: `npx eslint --fix .`
- **prettier** — format code consistently: `npx prettier --write .`

Auto-fix what can be auto-fixed. Report unfixable issues to the user.
LINT
      ;;
    rust)
      cat <<'LINT'

---

# Linting and Formatting

Before considering code complete, run the following tools on all changed files. If a tool is not installed, skip it and suggest the install command to the user.

- **rustfmt** — format Rust source code: `cargo fmt`
- **clippy** — catch common Rust mistakes and improve code: `cargo clippy -- -D warnings`

Auto-fix what can be auto-fixed. Report unfixable issues to the user.
LINT
      ;;
    terraform)
      cat <<'LINT'

---

# Linting and Formatting

Before considering code complete, run the following tools on all changed files. If a tool is not installed, skip it and suggest the install command to the user.

- **terraform fmt** — format Terraform configuration files: `terraform fmt -recursive`
- **terraform validate** — validate Terraform configuration: `terraform validate`
- **tflint** — Terraform linter for best practices: `tflint --recursive`

Auto-fix what can be auto-fixed. Report unfixable issues to the user.
LINT
      ;;
    ansible)
      cat <<'LINT'

---

# Linting and Formatting

Before considering code complete, run the following tools on all changed files. If a tool is not installed, skip it and suggest the install command to the user.

- **ansible-lint** — lint Ansible playbooks and roles: `ansible-lint`

Auto-fix what can be auto-fixed. Report unfixable issues to the user.
LINT
      ;;
    kubernetes)
      cat <<'LINT'

---

# Linting and Formatting

Before considering code complete, run the following tools on all changed files. If a tool is not installed, skip it and suggest the install command to the user.

- **kubeval/kubeconform** — validate Kubernetes manifests against schemas: `kubeconform -strict .`
- **helm lint** — lint Helm charts for issues: `helm lint ./chart`

Auto-fix what can be auto-fixed. Report unfixable issues to the user.
LINT
      ;;
    ai|security)
      # No linting section for these categories
      ;;
  esac
}

# Generate security scanning section
generate_security_section() {
  cat <<'SEC'

---

# Vulnerability Scanning

Before considering security-sensitive code complete, run these scanning tools. If a tool is not installed, skip it and suggest the install command to the user.

- **trivy** — filesystem and dependency vulnerability scanning: `trivy fs .`
  Install: `brew install trivy` or see https://aquasecurity.github.io/trivy
- **semgrep** — OWASP top 10 pattern detection: `semgrep --config auto`
  Install: `pip install semgrep` or see https://semgrep.dev
- **gitleaks** — secret detection in git repositories: `gitleaks detect --source .`
  Install: `brew install gitleaks` or see https://github.com/gitleaks/gitleaks

Run all three tools and address findings before merging.

---

# Unsafe Code Detection

When reviewing code, flag the following dangerous patterns:

- **SQL injection** — raw SQL queries built with string concatenation or interpolation. Always use parameterized queries or prepared statements.
- **Command injection** — unsanitized user input passed to shell execution functions (e.g., `os.system()`, `exec()`, `child_process.exec()`). Use allow-lists and avoid shell invocation.
- **XSS (Cross-Site Scripting)** — unescaped user input rendered in HTML output. Always escape or sanitize output contextually.
- **Path traversal** — unsanitized file paths that could resolve outside intended directories (e.g., `../../etc/passwd`). Canonicalize and validate paths against a base directory.
- **Deserialization attacks** — untrusted data passed to deserialization functions (e.g., `pickle.loads()`, `yaml.load()`, `JSON.parse()` with reviver abuse). Use safe loaders and validate schemas.
- **SSRF (Server-Side Request Forgery)** — user-controlled URLs used in server-side HTTP requests. Validate and restrict URLs to allowed hosts and schemes.
SEC
}

# Main loop: iterate over category directories
for category_dir in "${SCRIPT_DIR}"/*/; do
  category="$(basename "${category_dir}")"

  # Skip non-principle directories
  if [[ " ${SKIP_DIRS} " == *" ${category} "* ]]; then
    continue
  fi

  # Skip if no .md files
  shopt -s nullglob
  md_files=("${category_dir}"*.md)
  shopt -u nullglob
  if [[ ${#md_files[@]} -eq 0 ]]; then
    continue
  fi

  output_file="${SKILLS_DIR}/${category}-principles.md"

  # Display names for categories that need special casing
  declare -A DISPLAY_NAMES=(
    [ai]="AI"
    [nodejs]="Node.js"
  )
  capitalized="${DISPLAY_NAMES[${category}]:-${category^}}"

  {
    # YAML frontmatter
    echo "---"
    echo "name: ${category}-principles"
    echo "description: \"${TRIGGERS[${category}]}\""
    echo "---"
    echo ""

    # Header
    echo "# ${capitalized} Principles"
    echo ""
    echo "These are non-negotiable coding standards -- if you are about to write code that violates a principle, stop and fix it. When reviewing code, flag any violations."
    echo ""

    # Concatenate principle files in filename order with separators
    first=true
    for md_file in "${md_files[@]}"; do
      if [[ "${first}" == true ]]; then
        first=false
      else
        echo ""
        echo "---"
        echo ""
      fi
      cat "${md_file}"
    done

    # Add linting or security section
    if [[ "${category}" == "security" ]]; then
      generate_security_section
    else
      generate_linting_section "${category}"
    fi
  } > "${output_file}"

  echo "Generated: ${output_file}"
done

echo "Done. All skill files generated in ${SKILLS_DIR}/"
