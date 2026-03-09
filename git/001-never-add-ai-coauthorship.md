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
