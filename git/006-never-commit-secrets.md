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
