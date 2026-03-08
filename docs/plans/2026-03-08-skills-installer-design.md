# Design: Skills Installer with Auto-Update

**Date:** 2026-03-08
**Status:** Approved

## Summary

A single bash installer script (`install-skills.sh`) downloadable via curl that installs the 10 principle skills to Claude Code's skills directory (global or local), sets up a session-start hook that checks for updates once per day, and notifies the user in Claude when updates are available.

## Installer (`install-skills.sh`)

- Downloadable via: `curl -sSL https://raw.githubusercontent.com/asciifylabs/agentic-principles/main/install-skills.sh | bash`
- Flags: `--global` (default prompt), `--local`, `--update`, `--uninstall`
- Downloads all 10 skill `.md` files from GitHub raw content (no clone needed)
- Installs to:
  - Global: `~/.claude/skills/agentic-principles/`
  - Local: `.claude/skills/agentic-principles/` (current project)
- Stores version metadata in `~/.claude/scripts/.agentic-principles-version`
- Installs update-check hook script to `~/.claude/scripts/agentic-principles-update-check.sh`
- Registers hook in `~/.claude/settings.json` (merges, doesn't overwrite)
- `--update` re-downloads all skills, updates version file
- `--uninstall` removes skills, hook script, and hook registration

## Update Check Hook

- Script: `~/.claude/scripts/agentic-principles-update-check.sh`
- Registered as `SessionStart` hook in `~/.claude/settings.json`
- On session start:
  1. Read `.agentic-principles-version` for installed SHA and last-check timestamp
  2. If last check < 24 hours ago, exit silently (cache hit)
  3. If 24+ hours, run `git ls-remote` to get current main SHA
  4. If SHA matches, update timestamp, exit silently
  5. If SHA differs, output update-available message for Claude to relay
  6. If network unavailable, exit silently
- Non-blocking, runs quickly

## Version File Format

```
SHA=abc123def456
LAST_CHECK=1741430400
INSTALL_DIR=/home/user/.claude/skills/agentic-principles
```

Stored at: `~/.claude/scripts/.agentic-principles-version`

## Hook Registration

```json
{
  "hooks": {
    "SessionStart": [
      {
        "type": "command",
        "command": "bash ~/.claude/scripts/agentic-principles-update-check.sh"
      }
    ]
  }
}
```

Merged into existing `~/.claude/settings.json` without overwriting other entries.

## File Layout

```
~/.claude/
├── skills/
│   └── agentic-principles/
│       ├── security-principles.md
│       ├── shell-principles.md
│       ├── go-principles.md
│       ├── python-principles.md
│       ├── nodejs-principles.md
│       ├── rust-principles.md
│       ├── terraform-principles.md
│       ├── ansible-principles.md
│       ├── kubernetes-principles.md
│       └── ai-principles.md
├── scripts/
│   ├── agentic-principles-update-check.sh
│   └── .agentic-principles-version
└── settings.json  (hook entry merged in)
```

For `--local`, skills go in `.claude/skills/agentic-principles/` in the project. Hook and version file always live in `~/.claude/scripts/` (global).
