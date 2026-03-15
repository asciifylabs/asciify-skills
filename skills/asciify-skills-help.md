---
name: asciify-skills:help
description: "Show asciify-skills status, installed skills, and available commands"
---

# Asciify Skills Help

Show the user the current status of their asciify-skills installation.

## Steps

1. Check for installations:
   - Global skills: `~/.claude/skills/asciify-skills/`
   - Global commands: `~/.claude/commands/asciify-skills/`
   - Local skills: `.claude/skills/asciify-skills/`
   - Local commands: `.claude/commands/asciify-skills/`

2. For each installation found, read `.version` and list the installed skill files.

3. Display a summary like:

```
Asciify Skills — Status

Skills location: ~/.claude/skills/asciify-skills/
Commands location: ~/.claude/commands/asciify-skills/
Version: <sha from .version>

Installed skills (auto-triggered):
  - ai-principles          — AI/ML code
  - ansible-principles      — Ansible playbooks and roles
  - docker-principles       — Dockerfiles and containers
  - git-principles          — Git operations
  - go-principles           — Go code
  - kubernetes-principles   — Kubernetes manifests and Helm charts
  - nodejs-principles       — JavaScript/TypeScript
  - python-principles       — Python code
  - rust-principles         — Rust code
  - security-principles     — All code (always active)
  - shell-principles        — Shell scripts
  - terraform-principles    — Terraform/OpenTofu code

Commands:
  /asciify-skills:update      — Update to the latest version
  /asciify-skills:uninstall   — Remove asciify-skills
  /asciify-skills:help        — Show this help
```

4. If no installation is found, tell the user how to install:
```
Asciify Skills is not installed. Install with:

  curl -sSL https://raw.githubusercontent.com/asciifylabs/asciify-skills/main/install.sh | bash
```
