---
name: shell-principles
description: "Use when writing, reviewing, or modifying shell scripts (.sh, .bash, Makefile, Dockerfile)"
---

# Shell Principles

These are non-negotiable coding standards -- if you are about to write code that violates a principle, stop and fix it. When reviewing code, flag any violations.

# Use `set -euo pipefail`

> Start every shell script with `set -euo pipefail` to fail fast on errors, unset variables, and broken pipes.

## Rules

- Always place `set -euo pipefail` immediately after the shebang line
- `-e`: exits immediately if any command returns non-zero
- `-u`: exits if an unset variable is referenced
- `-o pipefail`: exits if any command in a pipeline fails, not just the last one
- Use `|| true` or `|| :` for commands where failure is intentionally acceptable
- Do not remove these flags to silence errors -- fix the root cause instead

## Example

```bash
#!/bin/bash
set -euo pipefail

# Script will exit if any command fails
# Script will exit if $UNDEFINED_VAR is used
# Script will exit if grep fails in: cat file | grep pattern
```

---

# Use Functions for Reusability

> Encapsulate reusable logic in functions to reduce duplication and improve readability.

## Rules

- Extract repeated or logically distinct operations into named functions
- Define functions before they are called
- Use `local` for all variables inside functions
- Return success/failure via exit codes (0 for success, non-zero for failure)
- Give functions descriptive verb-noun names (e.g., `check_disk_space`, `log_error`)
- Keep functions focused on a single responsibility

## Example

```bash
#!/bin/bash
set -euo pipefail

log_error() {
    local message="$1"
    echo "[ERROR] $(date '+%Y-%m-%d %H:%M:%S') - $message" >&2
}

check_disk_space() {
    local threshold="${1:-80}"
    local usage=$(df -h / | awk 'NR==2 {print $5}' | sed 's/%//')

    if [ "$usage" -gt "$threshold" ]; then
        log_error "Disk usage is ${usage}%, exceeding threshold of ${threshold}%"
        return 1
    fi
    return 0
}
```

---

# Proper Error Handling

> Use `trap`, explicit return code checks, and stderr for all error paths to ensure scripts fail gracefully and clean up after themselves.

## Rules

- Use `set -euo pipefail` as the foundation
- Use `trap cleanup EXIT` to guarantee cleanup runs on any exit (success or failure)
- Check return codes explicitly when a command's failure needs special handling
- Send all error messages to stderr (`>&2`), never stdout
- Exit with meaningful non-zero exit codes on failure
- Provide actionable error messages that name what failed and why

## Example

```bash
#!/bin/bash
set -euo pipefail

cleanup() {
    local exit_code=$?
    if [ $exit_code -ne 0 ]; then
        echo "Script failed with exit code $exit_code" >&2
    fi
    rm -f /tmp/tempfile.$$
}

trap cleanup EXIT

if ! command -v required_tool >/dev/null 2>&1; then
    echo "Error: required_tool not found" >&2
    exit 1
fi
```

---

# Always Quote Variables

> Wrap all variable expansions and command substitutions in double quotes to prevent word splitting and glob expansion.

## Rules

- Always quote variable expansions: `"$var"` not `$var`
- Always quote command substitutions: `"$(command)"` not `$(command)`
- Always quote array expansions: `"${array[@]}"`
- Use `"$@"` to pass through all positional parameters
- Use `"$*"` only when you intentionally want a single concatenated string
- Never leave variables unquoted unless you explicitly need word splitting

## Example

```bash
#!/bin/bash
set -euo pipefail

# Good: Quoted variables
filename="/path/to/file with spaces.txt"
cp "$filename" "/backup/$filename"

# Bad: Unquoted (will break with spaces)
cp $filename /backup/$filename

# Good: Quoted command substitution
count=$(wc -l < "$filename")

# Good: Quoted array expansion
files=("file1.txt" "file2.txt")
for file in "${files[@]}"; do
    echo "Processing: $file"
done
```

---

# Use Local Variables in Functions

> Declare all function variables with `local` to prevent accidental modification of global state.

## Rules

- Declare every variable inside a function with `local`
- Place `local` declarations at the top of the function body
- Only use global variables for intentionally shared script-wide state
- Never modify global variables from inside a function without explicit intent

## Example

```bash
#!/bin/bash
set -euo pipefail

global_config="/etc/config"

process_file() {
    local filename="$1"
    local temp_dir="/tmp/processing"
    local counter=0

    # These variables won't affect global scope
    mkdir -p "$temp_dir"
    # ... processing logic
}

# global_config remains unchanged by process_file
```

---

# Validate All Inputs

> Check every argument, file, and environment variable before use -- fail early with a clear error message.

## Rules

- Verify the correct number of arguments at script start
- Check file/directory existence (`-f`, `-d`) before operating on them
- Check permissions (`-r`, `-w`, `-x`) before file operations
- Validate data formats (numeric, non-empty) where applicable
- Print a usage message to stderr and exit non-zero on invalid input
- Sanitize inputs to prevent injection attacks

## Example

```bash
#!/bin/bash
set -euo pipefail

usage() {
    echo "Usage: $0 <source_file> <destination_dir>" >&2
    exit 1
}

validate_inputs() {
    if [ $# -ne 2 ]; then
        usage
    fi

    local source="$1"
    local dest="$2"

    if [ ! -f "$source" ]; then
        echo "Error: Source file '$source' does not exist" >&2
        exit 1
    fi

    if [ ! -d "$dest" ]; then
        echo "Error: Destination directory '$dest' does not exist" >&2
        exit 1
    fi

    if [ ! -w "$dest" ]; then
        echo "Error: Destination directory '$dest' is not writable" >&2
        exit 1
    fi
}

validate_inputs "$@"
```

---

# Use Temporary Files Safely

> Create temp files with `mktemp` and always clean them up via a `trap` on EXIT.

## Rules

- Always use `mktemp` to create temporary files (never hand-craft temp file names)
- Use `mktemp -d` when you need a temporary directory
- Register a `trap cleanup EXIT` to remove temp files on any exit
- Set restrictive permissions on temp files containing sensitive data
- Never assume `/tmp/somefile` is safe to use directly -- another process may control it

## Example

```bash
#!/bin/bash
set -euo pipefail

TEMP_FILE=$(mktemp /tmp/script.XXXXXX)

cleanup() {
    rm -f "$TEMP_FILE"
}

trap cleanup EXIT

echo "Processing data" > "$TEMP_FILE"
# ... operations on TEMP_FILE

# Cleanup happens automatically on exit
```

---

# Structured Logging

> Log with consistent levels (INFO/WARN/ERROR/DEBUG), timestamps, and script context to stderr.

## Rules

- Use log level functions (`log_info`, `log_error`, `log_warn`, `log_debug`) instead of raw `echo`
- Include ISO-8601 timestamps and the script name in every log line
- Send all log output to stderr (`>&2`) so stdout stays clean for data
- Gate DEBUG logs behind a `DEBUG` environment variable
- Use a single shared `log` function to enforce format consistency

## Example

```bash
#!/bin/bash
set -euo pipefail

SCRIPT_NAME=$(basename "$0")

log() {
    local level="$1"
    shift
    echo "[$level] [$(date '+%Y-%m-%d %H:%M:%S')] [$SCRIPT_NAME] $*" >&2
}

log_info()  { log "INFO" "$@"; }
log_error() { log "ERROR" "$@"; }
log_warn()  { log "WARN" "$@"; }
log_debug() { [ "${DEBUG:-0}" = "1" ] && log "DEBUG" "$@"; }

log_info "Starting backup process"
log_error "Failed to connect to server"
```

---

# Avoid Hardcoded Paths

> Use environment variables with defaults and dynamic path detection instead of hardcoded absolute paths.

## Rules

- Define configurable paths via environment variables with sensible defaults: `"${VAR:-default}"`
- Detect the script's own directory dynamically using `BASH_SOURCE`
- Use standard variables (`$HOME`, `$USER`, `$TMPDIR`) instead of hardcoding equivalents
- Never embed machine-specific paths (e.g., `/home/alice/`) in scripts
- Provide overrides for every path so scripts work across dev, CI, and production environments

## Example

```bash
#!/bin/bash
set -euo pipefail

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Use environment variables with defaults
BACKUP_DIR="${BACKUP_DIR:-$HOME/backups}"
LOG_DIR="${LOG_DIR:-/var/log}"
CONFIG_FILE="${CONFIG_FILE:-$SCRIPT_DIR/config.conf}"

echo "Script location: $SCRIPT_DIR"
echo "Backup directory: $BACKUP_DIR"
```

---

# Use Here Documents for Multi-line Strings

> Use heredocs (`<<EOF`) to generate multi-line content instead of repeated echo statements or string concatenation.

## Rules

- Use heredocs for any multi-line output: config files, SQL, templates, usage text
- Use `<<-EOF` (with dash) to allow leading-tab indentation inside functions
- Use `<<'EOF'` (quoted delimiter) when you want to suppress variable expansion
- Prefer `cat <<EOF` over multiple `echo` statements for readability
- Do not use string concatenation or escaped newlines for multi-line content

## Example

```bash
#!/bin/bash
set -euo pipefail

generate_config() {
    local hostname="$1"
    local port="${2:-8080}"

    cat > /etc/app.conf <<-EOF
		# Application Configuration
		# Generated on $(date)

		server {
		    hostname = "$hostname"
		    port = $port
		    timeout = 30
		}

		logging {
		    level = "info"
		    file = "/var/log/app.log"
		}
	EOF
}
```

---

# Check Command Existence Before Use

> Verify all external command dependencies at script startup using `command -v` and fail immediately if any are missing.

## Rules

- Use `command -v cmd >/dev/null 2>&1` to test for command availability (prefer over `which`)
- Check all dependencies at the top of the script, before any work begins
- Report all missing commands at once, not one at a time
- Include the missing command names in the error message
- Exit non-zero if any required command is missing

## Example

```bash
#!/bin/bash
set -euo pipefail

check_dependencies() {
    local missing_deps=()

    for cmd in jq curl awk; do
        if ! command -v "$cmd" >/dev/null 2>&1; then
            missing_deps+=("$cmd")
        fi
    done

    if [ ${#missing_deps[@]} -gt 0 ]; then
        echo "Error: Missing required commands: ${missing_deps[*]}" >&2
        echo "Please install: ${missing_deps[*]}" >&2
        exit 1
    fi
}

check_dependencies

# Now safe to use jq, curl, awk
```

---

# Use Arrays for Multiple Values

> Store lists of values in bash arrays instead of space-separated strings to correctly handle entries with spaces and special characters.

## Rules

- Use arrays for any list of items: files, options, arguments
- Always quote array expansions: `"${array[@]}"`
- Append with `+=`: `array+=("new_item")`
- Get length with `"${#array[@]}"`
- Iterate with `for item in "${array[@]}"; do ... done`
- Never use unquoted space-separated strings as a substitute for arrays
- Note: arrays require bash -- they are not available in POSIX sh

## Example

```bash
#!/bin/bash
set -euo pipefail

# Good: Using arrays
files=("file1.txt" "file with spaces.txt" "file2.txt")

for file in "${files[@]}"; do
    echo "Processing: $file"
done

# Appending to array
files+=("newfile.txt")

# Array length
echo "Total files: ${#files[@]}"

# Bad: Space-separated string (breaks with spaces)
files="file1.txt file with spaces.txt"
for file in $files; do  # This will split incorrectly
    echo "$file"
done
```

---

# Linting and Formatting

Before considering code complete, run the following tools on all changed files. If a tool is not installed, skip it and suggest the install command to the user.

- **shellcheck** — static analysis for shell scripts: `shellcheck script.sh`
- **shfmt** — format shell scripts consistently: `shfmt -w script.sh`

Auto-fix what can be auto-fixed. Report unfixable issues to the user.
