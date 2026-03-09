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
