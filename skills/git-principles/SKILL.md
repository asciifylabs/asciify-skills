---
name: git-principles
description: "Use when creating git commits, writing commit messages, or performing any git operations"
---

# Git Principles

These are non-negotiable coding standards -- if you are about to write code that violates a principle, stop and fix it. When reviewing code, flag any violations.

# Never Add AI Co-Authorship

> Never attribute commits to AI. Commits should appear as the user's own work with no AI involvement indicated.

## Rules

- Never add `Co-Authored-By` trailers that reference AI models or tools (e.g., Claude, GPT, Copilot)
- Never add `Signed-off-by` trailers attributing AI tools
- Never add any commit trailer, footer, or metadata that indicates AI involvement
- This applies to all commits: regular commits, merge commits, squash commits, and amended commits
- Write commit messages that describe the change clearly — do not mention AI assistance in the message body

## Example

```bash
# Bad: AI co-authorship trailer
git commit -m "feat: add user authentication

Co-Authored-By: Claude <noreply@anthropic.com>"

# Bad: AI attribution in any form
git commit -m "feat: add user authentication

Generated-By: Claude
AI-Assisted: true"

# Good: clean commit, no AI attribution
git commit -m "feat: add user authentication"
```

---

# Pull and Rebase Before Committing

> Always pull the latest changes and rebase before committing to avoid merge conflicts and keep history linear.

## Rules

- Run `git pull --rebase` on the current branch before creating any commit
- If the pull results in conflicts, resolve them before proceeding with the commit
- Never commit on top of a stale local branch when the remote has advanced
- Use rebase instead of merge to integrate upstream changes — this keeps history clean and linear
- After rebasing, verify the working tree is clean before committing new changes

## Example

```bash
# Bad: commit without pulling latest changes
git add src/auth.py
git commit -m "feat: add login endpoint"
# Remote has diverged — now you need a merge commit or force push

# Good: pull and rebase first, then commit
git pull --rebase
# Resolve any conflicts if needed
git add src/auth.py
git commit -m "feat: add login endpoint"
```

---

# Write Conventional Commit Messages

> Use the Conventional Commits format to produce a consistent, parseable commit history.

## Rules

- Structure commit messages as `type(scope): description` where scope is optional
- Use standard types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`, `ci`, `perf`, `build`
- Keep the subject line under 72 characters
- Use the imperative mood in the subject line (e.g., "add" not "added" or "adds")
- Add a blank line between subject and body when a body is needed
- Use the body to explain **what** and **why**, not how — the diff shows how

## Example

```bash
# Bad: vague, no type, past tense
git commit -m "changed stuff"

# Bad: too long, no convention
git commit -m "I updated the user service to fix the bug where login failed when email had uppercase letters"

# Good: conventional, concise, imperative
git commit -m "fix(auth): normalize email to lowercase before lookup"

# Good: with body for complex changes
git commit -m "refactor(db): replace raw SQL with query builder

Migrate all database queries to use the query builder to prevent
SQL injection and improve maintainability across repositories."
```

---

# Commit Atomic Changes

> Each commit should represent a single logical change that can be understood, reviewed, and reverted independently.

## Rules

- Stage specific files with `git add <file>` rather than `git add -A` or `git add .`
- Never bundle unrelated changes into a single commit
- If a task involves multiple logical steps, make multiple commits
- Each commit should leave the codebase in a working state — never commit broken code intentionally
- Use `git add -p` to stage partial file changes when a file contains multiple logical changes

## Example

```bash
# Bad: one giant commit with unrelated changes
git add -A
git commit -m "add auth, fix typos, update deps, refactor logging"

# Good: separate atomic commits
git add src/auth.py src/auth_test.py
git commit -m "feat(auth): add JWT token validation"

git add requirements.txt
git commit -m "chore(deps): upgrade pyjwt to 2.8.0"

git add src/logger.py
git commit -m "refactor(logging): switch to structured JSON output"
```

---

# Use Branches for Features

> Develop features, fixes, and experiments on dedicated branches — never commit directly to main.

## Rules

- Create a branch for each feature, bugfix, or task using a descriptive name
- Use a consistent naming convention: `feat/`, `fix/`, `chore/`, `refactor/`, `docs/` prefixes
- Keep branches short-lived — merge or rebase frequently to avoid long-lived divergence
- Delete branches after they are merged
- Never force-push to shared branches (main, develop) without explicit approval

## Example

```bash
# Bad: committing directly to main
git checkout main
git commit -m "feat: add search"

# Good: feature branch workflow
git checkout -b feat/user-search
# ... make changes ...
git commit -m "feat(search): add full-text user search endpoint"
git push -u origin feat/user-search
# Create PR, get review, merge, then clean up:
git branch -d feat/user-search
```

---

# Never Commit Secrets

> Secrets, credentials, and sensitive configuration must never be committed to the repository.

## Rules

- Never commit `.env` files, API keys, tokens, passwords, or private keys
- Maintain a comprehensive `.gitignore` that excludes sensitive files (`.env`, `*.pem`, `*.key`, `credentials.json`)
- Use environment variables or a secrets manager for sensitive configuration
- If a secret is accidentally committed, treat it as compromised — rotate it immediately, then remove it from history
- Review `git diff` before every commit to verify no secrets are being staged

## Example

```bash
# Bad: committing secrets
git add .env
git commit -m "add config"

# Bad: hardcoded secret in code
API_KEY = "sk-live-abc123..."

# Good: .gitignore excludes sensitive files
echo ".env" >> .gitignore
echo "*.pem" >> .gitignore
echo "credentials.json" >> .gitignore

# Good: use environment variables
API_KEY = os.environ["API_KEY"]
```

---

# Review Changes Before Committing

> Always review staged changes before committing to catch mistakes, debug artifacts, and unintended modifications.

## Rules

- Run `git status` before committing to see what will be included
- Run `git diff --staged` to review the exact changes being committed
- Look for and remove debug statements, TODO comments, and temporary code
- Verify no unintended files (build artifacts, logs, IDE config) are staged
- Check that the changes match the intent of the commit message

---

# Use Git Hooks for Automation

> Leverage git hooks to enforce code quality and prevent bad commits before they enter the repository.

## Rules

- Use pre-commit hooks to run linters, formatters, and tests before commits
- Use commit-msg hooks to enforce conventional commit message format
- Use pre-push hooks to run full test suites before pushing
- Share hook configurations via tools like pre-commit, husky, or lefthook
- Never skip hooks with `--no-verify` unless there is a documented reason
- Keep hooks fast to avoid slowing down the development workflow
- Document required hooks in the project README or CONTRIBUTING guide

## Example

```yaml
# .pre-commit-config.yaml
repos:
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.5.0
    hooks:
      - id: trailing-whitespace
      - id: end-of-file-fixer
      - id: check-yaml
      - id: check-added-large-files
      - id: check-merge-conflict

  - repo: https://github.com/gitleaks/gitleaks
    rev: v8.18.0
    hooks:
      - id: gitleaks
```

```bash
# Install pre-commit hooks
pre-commit install
pre-commit install --hook-type commit-msg

# Run hooks against all files
pre-commit run --all-files
```

---

# Write Meaningful PR Descriptions

> Every pull request should clearly explain what changed, why, and how to verify it.

## Rules

- Include a summary of what the PR does and the motivation behind it
- Link to relevant issues, tickets, or discussions
- Describe how to test or verify the changes
- Call out any breaking changes, migrations, or deployment steps
- Keep PRs focused and small; split large changes into stacked PRs
- Use PR templates to ensure consistent information across the team
- Add screenshots or recordings for UI changes

## Example

```markdown
## Summary
- Add rate limiting middleware to the API gateway
- Fixes #142 (API abuse from unauthenticated clients)

## Changes
- New `RateLimiter` middleware using token bucket algorithm
- Redis-backed counter for distributed rate tracking
- Returns 429 with Retry-After header when limit exceeded

## Test plan
- [ ] Unit tests for token bucket logic
- [ ] Integration test with Redis
- [ ] Load test confirming 429 responses above threshold
```

---

# Keep a Clean History

> Maintain a readable, linear git history that tells the story of the project's evolution.

## Rules

- Prefer rebase over merge to keep a linear history on feature branches
- Squash fixup commits before merging to main
- Never rewrite history on shared branches (main, develop, release)
- Use `git commit --fixup` and `git rebase --autosquash` for corrections
- Delete merged branches to keep the branch list clean
- Avoid merge commits in feature branches; rebase onto the target branch instead
- Each commit in the final history should compile and pass tests

## Example

```bash
# Fixup a previous commit during development
git commit --fixup=abc1234
git rebase -i --autosquash main

# Rebase feature branch onto latest main before merging
git fetch origin
git rebase origin/main

# Delete merged branch
git branch -d feature/my-feature
git push origin --delete feature/my-feature
```

---

# Sign Commits for Integrity

> Use GPG or SSH signing to verify commit authorship and prevent impersonation.

## Rules

- Sign all commits with GPG or SSH keys
- Configure `commit.gpgsign = true` in git config for automatic signing
- Upload your public key to GitHub/GitLab for verified badges
- Use SSH signing (`gpg.format = ssh`) for simpler key management
- Require signed commits on protected branches via branch protection rules
- Never share or commit private signing keys

## Example

```bash
# Configure SSH signing (recommended)
git config --global gpg.format ssh
git config --global user.signingkey ~/.ssh/id_ed25519.pub
git config --global commit.gpgsign true

# Configure GPG signing
git config --global user.signingkey YOUR_GPG_KEY_ID
git config --global commit.gpgsign true

# Verify a signed commit
git log --show-signature -1

# Sign a tag
git tag -s v1.0.0 -m "Release v1.0.0"
```

---

# Protect Branches

> Use branch protection rules to enforce quality gates and prevent accidental or unauthorized changes to critical branches.

## Rules

- Enable branch protection on main, develop, and release branches
- Require pull request reviews before merging
- Require status checks (CI/CD) to pass before merging
- Prevent force pushes to protected branches
- Require branches to be up to date before merging
- Enable CODEOWNERS files to enforce review from domain experts
- Restrict who can push directly to protected branches

## Example

```bash
# GitHub CLI: set branch protection
gh api repos/{owner}/{repo}/branches/main/protection -X PUT -f \
  required_status_checks='{"strict":true,"contexts":["ci/build","ci/test"]}' \
  enforce_admins=true \
  required_pull_request_reviews='{"required_approving_review_count":1}'
```

```text
# CODEOWNERS
* @team/backend
/frontend/ @team/frontend
/infra/ @team/platform
*.tf @team/platform
```
