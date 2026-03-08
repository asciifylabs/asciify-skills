# Principles to Skills Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Convert 192 coding principles across 11 categories into 11 Claude Code skills with integrated linting and security scanning, replacing the hook-based delivery system.

**Architecture:** Each category directory's `.md` files are consolidated into a single skill file with YAML frontmatter, trigger description, linting instructions, and (for security) vulnerability scanning. A build script automates regeneration from source files. The old hook/install infrastructure is retired.

**Tech Stack:** Bash (build script), Markdown (skills), Claude Code skills format (YAML frontmatter)

---

### Task 1: Create skills directory

**Files:**
- Create: `skills/` directory

**Step 1: Create directory**

```bash
mkdir -p skills
```

**Step 2: Commit**

```bash
git add skills/.gitkeep
git commit -m "chore: create skills directory for principles-to-skills migration"
```

---

### Task 2: Build the consolidation script

**Files:**
- Create: `build-skills.sh`

**Step 1: Write build-skills.sh**

This script reads each category directory, concatenates all principle `.md` files in order, wraps them with YAML frontmatter and linting instructions, and outputs to `skills/<category>-principles.md`.

```bash
#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="$SCRIPT_DIR/skills"
mkdir -p "$SKILLS_DIR"

# Category definitions: category_dir|skill_name|trigger_description|linting_section
# Linting sections are appended after principles content
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
)

# Linting tools per category
declare -A LINTING=(
  [shell]="shellcheck,shfmt"
  [go]="gofmt,go vet,golangci-lint"
  [python]="ruff"
  [nodejs]="eslint,prettier"
  [rust]="rustfmt,clippy"
  [terraform]="terraform fmt,terraform validate,tflint"
  [ansible]="ansible-lint"
  [kubernetes]="kubeval/kubeconform,helm lint"
)

build_linting_section() {
  local category="$1"
  local tools="${LINTING[$category]:-}"
  if [ -z "$tools" ]; then
    return
  fi

  echo ""
  echo "---"
  echo ""
  echo "# Linting and Formatting"
  echo ""
  echo "Before considering code complete, run the following tools on all changed files. If a tool is not installed, skip it and suggest the install command to the user."
  echo ""

  IFS=',' read -ra TOOL_LIST <<< "$tools"
  for tool in "${TOOL_LIST[@]}"; do
    echo "- **${tool}**"
  done

  echo ""
  echo "Auto-fix what can be auto-fixed. Report unfixable issues to the user."
}

build_security_scanning_section() {
  cat << 'SECURITY_EOF'

---

# Security Scanning

Before considering security-sensitive work complete, run these scans:

## Vulnerability Scanning

- **trivy** (`trivy fs .`) — scan filesystem and dependencies for known vulnerabilities
- **semgrep** (`semgrep --config auto`) — pattern-based detection for OWASP top 10 vulnerabilities
- **gitleaks** (`gitleaks detect --source .`) — detect secrets in code and git history

If a tool is not installed, skip it and suggest the install command:
- trivy: `brew install trivy` or see https://aquasecurity.github.io/trivy
- semgrep: `pip install semgrep` or `brew install semgrep`
- gitleaks: `brew install gitleaks` or see https://github.com/gitleaks/gitleaks

## Unsafe Code Detection

Always scan for and flag these patterns:

- **SQL injection** — raw queries, string concatenation/interpolation in SQL
- **Command injection** — unsanitized input passed to shell/exec calls
- **XSS** — unescaped user content rendered in HTML/templates
- **Path traversal** — unsanitized file paths from user input (e.g., `../../../etc/passwd`)
- **Deserialization attacks** — deserializing untrusted data (pickle, yaml.load, JSON.parse of executable content)
- **SSRF** — user-controlled URLs in server-side HTTP requests

When any of these patterns are detected, flag them immediately and suggest the secure alternative.
SECURITY_EOF
}

for category_dir in "$SCRIPT_DIR"/*/; do
  category=$(basename "$category_dir")

  # Skip non-principle directories
  [[ "$category" == "skills" || "$category" == "docs" || "$category" == ".claude" || "$category" == ".git" ]] && continue

  # Skip if no principle files
  shopt -s nullglob
  files=("$category_dir"*.md)
  shopt -u nullglob
  [ ${#files[@]} -eq 0 ] && continue

  trigger="${TRIGGERS[$category]:-}"
  [ -z "$trigger" ] && continue

  skill_file="$SKILLS_DIR/${category}-principles.md"

  # Build skill file
  {
    # YAML frontmatter
    echo "---"
    echo "name: ${category}-principles"
    echo "description: ${trigger}"
    echo "---"
    echo ""
    echo "# ${category^} Principles"
    echo ""
    echo "These are non-negotiable coding standards. If you are about to write code that violates a principle, stop and fix it. When reviewing code, flag any violations."
    echo ""

    # Concatenate all principle files in order
    for f in "${files[@]}"; do
      cat "$f"
      echo ""
      echo "---"
      echo ""
    done

    # Add linting section
    build_linting_section "$category"

    # Add security scanning section (security category only)
    if [ "$category" = "security" ]; then
      build_security_scanning_section
    fi

  } > "$skill_file"

  echo "Built: $skill_file ($(wc -l < "$skill_file") lines)"
done

echo ""
echo "All skills built in $SKILLS_DIR/"
```

**Step 2: Make executable and test**

Run: `chmod +x build-skills.sh && bash build-skills.sh`
Expected: Output showing each skill built with line counts, 10 skill files created in `skills/`.

**Step 3: Verify output**

Run: `ls -la skills/ && head -10 skills/security-principles.md && head -10 skills/shell-principles.md`
Expected: 10 `.md` files with correct YAML frontmatter.

**Step 4: Commit**

```bash
git add build-skills.sh
git commit -m "feat: add build script to consolidate principles into skills"
```

---

### Task 3: Run the build and verify all 10 skill files

**Step 1: Run the build**

Run: `bash build-skills.sh`

**Step 2: Verify each skill has correct frontmatter**

Run: `for f in skills/*.md; do echo "=== $(basename $f) ==="; head -4 "$f"; echo; done`
Expected: Each file starts with `---`, `name:`, `description:`, `---`.

**Step 3: Verify security skill has scanning section**

Run: `grep -c "trivy\|semgrep\|gitleaks\|SQL injection\|Command injection\|XSS" skills/security-principles.md`
Expected: 6+ matches.

**Step 4: Verify linting sections exist for language skills**

Run: `grep -l "Linting and Formatting" skills/*.md`
Expected: shell, go, python, nodejs, rust, terraform, ansible, kubernetes (8 files).

**Step 5: Commit generated skills**

```bash
git add skills/
git commit -m "feat: generate 10 skill files from principles with linting and security scanning"
```

---

### Task 4: Update CLAUDE.md — remove bootstrap, keep project instructions

**Files:**
- Modify: `CLAUDE.md`

**Step 1: Replace CLAUDE.md content**

Remove the entire initialization script block. Keep git commit policy. Add skills reference.

```markdown
# Agentic Principles

## Git Commit Policy

You MAY commit when the user asks you to. **Never run `git push`** — always let the user push themselves.

- **Never add AI co-authorship** — do not add `Co-Authored-By`, `Signed-off-by`, or any trailer that attributes the commit to an AI. Commits should appear as the user's own work.
- Write clear, conventional commit messages that describe the change
- Stage specific files rather than using `git add -A` or `git add .`
- Show `git status` and `git diff` before committing so the user can review
- Never commit files that contain secrets (`.env`, credentials, API keys)

## Coding Principles

This repository provides coding principles as Claude Code skills. Each skill triggers automatically based on the code you're working with. The principles are non-negotiable coding standards — if you are about to write code that violates a principle, stop and fix it. When reviewing code, flag any violations.
```

**Step 2: Commit**

```bash
git add CLAUDE.md
git commit -m "refactor: replace CLAUDE.md bootstrap script with skills-based approach"
```

---

### Task 5: Update AGENTS.md — same treatment

**Files:**
- Modify: `AGENTS.md`

**Step 1: Replace AGENTS.md content**

```markdown
# Agentic Principles

## Git Commit Policy

You MAY commit when the user asks you to. **Never run `git push`** — always let the user push themselves.

- **Never add AI co-authorship** — do not add `Co-Authored-By`, `Signed-off-by`, or any trailer that attributes the commit to an AI. Commits should appear as the user's own work.
- Write clear, conventional commit messages that describe the change
- Stage specific files rather than using `git add -A` or `git add .`
- Show `git status` and `git diff` before committing so the user can review
- Never commit files that contain secrets (`.env`, credentials, API keys)

## Coding Principles

This repository provides coding principles as skills. Install the skills for your AI coding agent to automatically apply language-specific coding standards, linting, and security scanning.
```

**Step 2: Commit**

```bash
git add AGENTS.md
git commit -m "refactor: replace AGENTS.md bootstrap script with skills-based approach"
```

---

### Task 6: Remove retired infrastructure

**Files:**
- Delete: `install.sh`
- Delete: `.claude/hooks/fetch-principles.sh`
- Delete: `.claude/hooks/format-lint.sh`
- Delete: `.claude/hooks/git-hooks/pre-commit`
- Delete: `.claude/hooks/git-hooks/post-checkout`
- Delete: `.claude/hooks/git-hooks/post-merge`
- Delete: `claude-settings.json`

**Step 1: Remove files**

```bash
git rm install.sh
git rm claude-settings.json
git rm -r .claude/hooks/
```

**Step 2: Commit**

```bash
git commit -m "chore: remove hook-based infrastructure replaced by skills"
```

---

### Task 7: Create skills README

**Files:**
- Create: `skills/README.md`

**Step 1: Write README**

```markdown
# Agentic Principles — Skills

These skills provide coding principles, linting, and security scanning for Claude Code.

## Available Skills

| Skill | Triggers On |
|-------|------------|
| `security-principles` | All code (always active) |
| `shell-principles` | .sh, .bash, Makefile, Dockerfile |
| `go-principles` | .go, go.mod, go.sum |
| `python-principles` | .py, pyproject.toml, requirements.txt |
| `nodejs-principles` | .js, .ts, .tsx, package.json |
| `rust-principles` | .rs, Cargo.toml |
| `terraform-principles` | .tf, .tfvars |
| `ansible-principles` | playbooks, roles, ansible.cfg |
| `kubernetes-principles` | Kubernetes manifests, Helm charts |
| `ai-principles` | AI/ML code (OpenAI, Anthropic, LangChain, etc.) |

## What Each Skill Includes

1. **Coding principles** — non-negotiable standards for that language/domain
2. **Linting instructions** — which tools to run and how (language skills)
3. **Security scanning** — trivy, semgrep, gitleaks, OWASP top 10 detection (security skill)

## Rebuilding Skills

If you modify the source principle files in the category directories, regenerate the skills:

```bash
bash build-skills.sh
```
```

**Step 2: Commit**

```bash
git add skills/README.md
git commit -m "docs: add skills README with usage and rebuild instructions"
```

---

### Task 8: Update project README

**Files:**
- Modify: `README.md`

**Step 1: Read current README**

Read the full README.md to understand what needs updating.

**Step 2: Update installation section**

Replace hook-based installation instructions with skills installation instructions. Keep the principles content documentation. Remove references to `install.sh`, hooks, `fetch-principles.sh`, and the bootstrap script.

**Step 3: Commit**

```bash
git add README.md
git commit -m "docs: update README for skills-based distribution"
```

---

### Task 9: End-to-end validation

**Step 1: Verify all skill files are valid**

Run: `for f in skills/*.md; do head -1 "$f" | grep -q '^---$' && echo "OK: $(basename $f)" || echo "FAIL: $(basename $f)"; done`
Expected: All 10 skills show OK.

**Step 2: Verify no stale files remain**

Run: `test ! -f install.sh && test ! -f claude-settings.json && test ! -d .claude/hooks && echo "Clean" || echo "Stale files remain"`
Expected: "Clean"

**Step 3: Verify build script is idempotent**

Run: `bash build-skills.sh && bash build-skills.sh && echo "Idempotent"`
Expected: Same output both times, no errors.

**Step 4: Verify security skill has all three layers**

Run: `grep -c "^#" skills/security-principles.md`
Expected: Principle headings + "Linting" + "Security Scanning" + "Vulnerability Scanning" + "Unsafe Code Detection" sections.

**Step 5: Count total principles preserved**

Run: `grep -c "^# " skills/*.md | grep -v README`
Expected: ~192 principle headings across all files (plus section headings for linting/scanning).
