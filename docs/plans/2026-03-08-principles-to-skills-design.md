# Design: Convert Principles to Skills

**Date:** 2026-03-08
**Status:** Approved

## Summary

Convert the 192 coding principles across 11 categories from the current hook-based injection system into 11 Claude Code skills. Each skill consolidates all principles for its category, includes relevant linting tool instructions, and triggers automatically based on file context. The security skill always triggers and includes vulnerability scanning with trivy, semgrep, and gitleaks.

## Motivation

- Skills are the emerging standard distribution format for Claude Code extensions
- The current system requires significant custom infrastructure (clone, hooks, caching, lockfiles, settings merge, technology auto-detection)
- Skills provide native on-demand loading with trigger-based activation
- Simpler adoption: install a skills package vs. running custom install scripts

## Architecture

### Skill files

```
skills/
├── security-principles.md
├── shell-principles.md
├── go-principles.md
├── python-principles.md
├── nodejs-principles.md
├── rust-principles.md
├── terraform-principles.md
├── ansible-principles.md
├── kubernetes-principles.md
├── ai-principles.md
└── README.md
```

### Skill format

Each skill is a single markdown file with frontmatter:

```yaml
---
name: <category>-principles
description: <trigger description>
---
```

Followed by:
1. All consolidated principles from that category
2. Linting/formatting tool instructions
3. (Security only) Vulnerability scanning instructions

### Trigger descriptions

| Skill | Trigger |
|-------|---------|
| security-principles | Use when writing, reviewing, or modifying any code in any language |
| shell-principles | Use when writing, reviewing, or modifying shell scripts (.sh, .bash, Makefile, Dockerfile) |
| go-principles | Use when writing, reviewing, or modifying Go code (.go, go.mod, go.sum) |
| python-principles | Use when writing, reviewing, or modifying Python code (.py, pyproject.toml, requirements.txt) |
| nodejs-principles | Use when writing, reviewing, or modifying JavaScript or TypeScript code (.js, .ts, .tsx, package.json) |
| rust-principles | Use when writing, reviewing, or modifying Rust code (.rs, Cargo.toml) |
| terraform-principles | Use when writing, reviewing, or modifying Terraform code (.tf, .tfvars) |
| ansible-principles | Use when writing, reviewing, or modifying Ansible code (playbooks, roles, ansible.cfg) |
| kubernetes-principles | Use when writing, reviewing, or modifying Kubernetes manifests or Helm charts |
| ai-principles | Use when writing, reviewing, or modifying AI/ML code using frameworks like OpenAI, Anthropic, LangChain, PyTorch, TensorFlow |

### Linting per skill

Each language skill includes instructions to run the appropriate linting/formatting tools before considering code complete:

| Skill | Linting tools |
|-------|--------------|
| shell-principles | shellcheck, shfmt |
| go-principles | gofmt, go vet, golangci-lint |
| python-principles | ruff (lint + format) |
| nodejs-principles | eslint, prettier |
| rust-principles | rustfmt, clippy |
| terraform-principles | terraform fmt, terraform validate, tflint |
| ansible-principles | ansible-lint |
| kubernetes-principles | kubeval/kubeconform, helm lint |
| ai-principles | inherits linting from the active language skill |

Skills instruct Claude to:
1. Run the linter/formatter on changed files
2. Auto-fix what can be auto-fixed
3. Report unfixable issues to the user
4. Gracefully skip tools that aren't installed, with install hints

### Security skill: three layers

1. **Code principles** - existing security rules (no hardcoded secrets, input validation, parameterized queries, etc.)
2. **Static analysis / vulnerability scanning** - run automatically when reviewing or completing security-sensitive work:
   - **trivy** (`trivy fs .`) - filesystem and dependency vulnerability scanning
   - **semgrep** (`semgrep --config auto`) - pattern-based OWASP top 10 detection
   - **gitleaks** (`gitleaks detect --source .`) - secret detection in code and git history
3. **Unsafe code detection** - explicit rules and scan focus areas:
   - SQL injection (raw queries, string concatenation in queries)
   - Command injection (unsanitized input in shell calls)
   - XSS (unescaped user output in HTML/templates)
   - Path traversal (unsanitized file path inputs)
   - Deserialization attacks (untrusted data deserialization)
   - SSRF (user-controlled URLs in server-side requests)

## What gets retired

- `CLAUDE.md` bootstrap/initialization script block
- `AGENTS.md` bootstrap/initialization script block
- `install.sh` (400 lines)
- `.claude/hooks/fetch-principles.sh` (362 lines)
- `.claude/hooks/format-lint.sh` (444 lines)
- `.claude/hooks/git-hooks/*` (pre-commit, post-checkout, post-merge)
- `claude-settings.json`
- Caching/lockfile system
- Technology auto-detection logic

## What stays (as source)

- Individual principle `.md` files in each category directory (source of truth for content)
- A build script to consolidate `category/*.md` files into single `skills/category-principles.md` files

## What replaces it

- `CLAUDE.md` becomes minimal: project-specific instructions only, no bootstrap
- `AGENTS.md` updated similarly
- Distribution via standard skills installation mechanism

## Build process

A build script reads each category directory, consolidates all principle files into a single skill file with the correct frontmatter, and outputs to `skills/`. This runs at release time, not at user install time.

## Migration path

1. Build the 11 skill files from existing principle sources
2. Create the build/consolidation script
3. Update CLAUDE.md and AGENTS.md to remove bootstrap blocks
4. Update README with new installation instructions
5. Deprecate the hook-based system
