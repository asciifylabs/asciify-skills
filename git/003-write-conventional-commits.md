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
