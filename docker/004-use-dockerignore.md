# Use .dockerignore

> Always include a `.dockerignore` file to exclude unnecessary files from the build context, reducing image size and preventing secrets from leaking into images.

## Rules

- Create a `.dockerignore` file in every project that uses Docker
- Exclude version control directories (`.git/`), IDE configs, and OS files
- Exclude secrets, credentials, and environment files (`.env`, `*.pem`, `*.key`)
- Exclude test files, documentation, and CI/CD configs that are not needed at runtime
- Exclude `node_modules/`, `__pycache__/`, `target/`, and other dependency/build directories — these should be installed fresh inside the build
- Exclude the `Dockerfile` itself and `docker-compose*.yml`
- Review `.dockerignore` when adding new file types to the project

## Example

```
# Bad: no .dockerignore — everything gets sent to the build context

# Good: comprehensive .dockerignore
.git
.gitignore
.env
.env.*
*.md
LICENSE
Dockerfile
docker-compose*.yml
.dockerignore

# IDE and OS
.vscode/
.idea/
*.swp
.DS_Store

# Dependencies and build artifacts
node_modules/
__pycache__/
*.pyc
target/
dist/
coverage/

# Secrets and credentials
*.pem
*.key
*.crt
credentials/
```
