# Claude Code Hook Setup

This guide explains how coding principles and linting hooks are loaded and kept up to date.

## How It Works

Add a `CLAUDE.md` or `AGENTS.md` to your repo root with the initialization script from this repository. The script:

1. Clones the principles repo to `/tmp/claude-principles-repo` (first run only)
2. Installs git hooks if not already present (`install.sh --non-interactive`)
3. On subsequent runs, fetches updated principles and refreshes installed hooks

### Auto-Update Flow

```
Session start (CLAUDE.md / AGENTS.md init script)
  -> fetch-principles.sh
    -> git pull on /tmp/claude-principles-repo
    -> Regenerate /tmp/claude-principles-active.md
    -> Sync hooks from repo clone into .git/hooks/

git checkout / git switch (post-checkout hook)
  -> fetch-principles.sh (in background)

git merge / git pull (post-merge hook)
  -> fetch-principles.sh (in background)

git commit (pre-commit hook)
  -> format-lint.sh (lint + auto-fix staged files)
```

All hooks prefer the **source copy** (repo's own `.claude/hooks/` or the principles repo clone) over the installed copy in `.git/hooks/`. This means updates to the principles repo propagate automatically without re-running `install.sh`.

## Supported Languages

The pre-commit hook auto-detects file types and runs appropriate tools:

| Language       | Formatter        | Linter            |
|----------------|------------------|-------------------|
| Shell          | `shfmt`          | `shellcheck`      |
| JavaScript/TSX | `prettier`       | `eslint`          |
| Python         | `ruff format`    | `ruff check`      |
| Go             | `gofmt`          | `golangci-lint`   |
| Rust           | `rustfmt`        | `clippy`          |
| Terraform      | `terraform fmt`  | `tflint`          |
| Ansible        | --               | `ansible-lint`    |
| Kubernetes     | --               | `kubeval`         |
| Markdown       | `prettier`       | --                |
| JSON           | `prettier`       | --                |
| YAML           | `prettier`       | --                |

Tools are only invoked if installed. Missing tools are skipped with an install hint.

## Configuration

Environment variables for `fetch-principles.sh`:

- `VERBOSE=true` -- Enable verbose logging
- `EXTRA_CATEGORIES="ansible kubernetes"` -- Add additional categories
- `PRINCIPLES_REPO_DIR=/custom/path` -- Custom cache directory
- `PRINCIPLES_OUTPUT=/custom/output.md` -- Custom output file
- `SKIP_SETTINGS=true` -- Disable automatic Claude Code settings merge
- `FORCE_REFRESH=true` -- Skip cache and force re-fetch

Environment variables for `format-lint.sh`:

- `FORMAT_LINT_MODE=fix|check` -- Auto-fix (default) or check-only
- `FORMAT_LINT_AUTO_INSTALL=true` -- Auto-install missing tools
- `VERBOSE=true` -- Enable verbose logging
