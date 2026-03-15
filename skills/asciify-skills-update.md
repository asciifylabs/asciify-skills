---
name: asciify-skills:update
description: "Update asciify-skills to the latest version from GitHub"
---

# Update Asciify Skills

You are updating the asciify-skills installation. Follow these steps exactly.

## Steps

1. Determine the install location by checking which directory exists:
   - Global: `~/.claude/skills/asciify-skills/`
   - Local (current project): `.claude/skills/asciify-skills/`
   - If both exist, update both. If neither exists, tell the user to install first.

2. Read the current version from `.version` in the install directory (if it exists).

3. Fetch the latest version metadata:
   ```bash
   curl -sSfL "https://raw.githubusercontent.com/asciifylabs/asciify-skills/main/skills/.version" 2>/dev/null
   ```

4. Download each skill file from GitHub and overwrite the local copy:
   ```bash
   REPO_RAW="https://raw.githubusercontent.com/asciifylabs/asciify-skills/main/skills"
   for file in \
     ai-principles.md \
     ansible-principles.md \
     docker-principles.md \
     git-principles.md \
     go-principles.md \
     kubernetes-principles.md \
     nodejs-principles.md \
     python-principles.md \
     rust-principles.md \
     security-principles.md \
     shell-principles.md \
     terraform-principles.md \
     .version; do
     curl -sSfL "${REPO_RAW}/${file}" -o "${INSTALL_DIR}/${file}"
   done
   ```

5. Update the slash command files in the commands directory:
   - For global installs, the commands directory is `~/.claude/commands/asciify-skills/`
   - For local installs, the commands directory is `.claude/commands/asciify-skills/`
   ```bash
   COMMANDS_DIR="${INSTALL_DIR/skills/commands}"
   mkdir -p "${COMMANDS_DIR}"
   for file in update.md uninstall.md help.md; do
     curl -sSfL "${REPO_RAW}/asciify-skills-${file}" -o "${COMMANDS_DIR}/${file}"
   done
   ```

6. Report what was updated: show the old and new version (SHA), and confirm success.

## Important

- Do NOT modify `~/.claude/settings.json`
- Do NOT register any hooks
- If `curl` fails for any file, report the error and stop
- Always show the user what changed before and after
