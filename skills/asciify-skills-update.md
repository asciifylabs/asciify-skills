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

4. Download each skill file from GitHub and overwrite the local copy. Skills use the `<name>/SKILL.md` subdirectory structure:
   ```bash
   REPO_RAW="https://raw.githubusercontent.com/asciifylabs/asciify-skills/main/skills"
   for skill in \
     ai-principles \
     ansible-principles \
     docker-principles \
     git-principles \
     go-principles \
     kubernetes-principles \
     nodejs-principles \
     python-principles \
     rust-principles \
     security-principles \
     shell-principles \
     terraform-principles; do
     mkdir -p "${INSTALL_DIR}/${skill}"
     curl -sSfL "${REPO_RAW}/${skill}/SKILL.md" -o "${INSTALL_DIR}/${skill}/SKILL.md"
   done
   curl -sSfL "${REPO_RAW}/.version" -o "${INSTALL_DIR}/.version"
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
