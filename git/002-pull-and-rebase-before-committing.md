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
