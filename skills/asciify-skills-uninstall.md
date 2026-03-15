---
name: asciify-skills:uninstall
description: "Remove asciify-skills from this machine"
---

# Uninstall Asciify Skills

You are uninstalling asciify-skills. Follow these steps exactly.

## Steps

1. Check for installations in both locations:
   - Global skills: `~/.claude/skills/asciify-skills/`
   - Global commands: `~/.claude/commands/asciify-skills/`
   - Local skills (current project): `.claude/skills/asciify-skills/`
   - Local commands (current project): `.claude/commands/asciify-skills/`

2. For each location that exists, confirm with the user before removing:
   - Show which location(s) will be removed
   - Ask "Remove asciify-skills from [location]? (y/n)"

3. Remove both the skills and commands directories:
   ```bash
   rm -rf <skills_dir>
   rm -rf <commands_dir>
   ```

4. Check if `~/.claude/settings.json` contains any leftover `asciify-skills` or `agentic-principles` hook entries. If so, offer to clean them up.

5. Confirm removal is complete.

## Important

- Always confirm with the user before deleting
- Remove both `skills/asciify-skills/` and `commands/asciify-skills/` directories
- Do NOT remove any other files in `.claude/skills/` or `.claude/commands/`
