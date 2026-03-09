# Review Changes Before Committing

> Always review staged changes before committing to catch mistakes, debug artifacts, and unintended modifications.

## Rules

- Run `git status` before committing to see what will be included
- Run `git diff --staged` to review the exact changes being committed
- Look for and remove debug statements, TODO comments, and temporary code
- Verify no unintended files (build artifacts, logs, IDE config) are staged
- Check that the changes match the intent of the commit message
