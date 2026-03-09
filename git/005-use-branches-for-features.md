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
