#!/usr/bin/env bash
# PreToolUse hook — matcher: Bash
# WARNS (does not block) on absolute paths in user-supplied filename args,
# except canonical system paths. Nudges toward relative paths.

set -euo pipefail

INPUT=$(cat)

if ! command -v jq >/dev/null 2>&1; then
    exit 0
fi

COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
[[ -z "$COMMAND" ]] && exit 0

# Canonical paths where absolute-path use is normal — don't warn
CANONICAL_ABS_PATHS_REGEX='^(/etc/|/var/|/usr/|/opt/|/home/|/tmp/|/dev/|/proc/|/sys/|/root/|'"$HOME"'|'"${CLAUDE_PROJECT_DIR:-/nonexistent}"')'

# Extract absolute paths from the command (heuristic — works for common cases)
NONCANONICAL_ABS=()
while IFS= read -r path; do
    [[ -z "$path" ]] && continue
    if ! echo "$path" | grep -qE "$CANONICAL_ABS_PATHS_REGEX"; then
        NONCANONICAL_ABS+=("$path")
    fi
done < <(echo "$COMMAND" | grep -oE '(^| )/[A-Za-z0-9_./-]+' | sed -E 's/^ //' | sort -u || true)

if [[ ${#NONCANONICAL_ABS[@]} -gt 0 ]]; then
    # Inject context (exit 0; stdout becomes context for next turn)
    echo "**Relative-path nudge:** the command uses absolute path(s) not in the canonical safe list:"
    for p in "${NONCANONICAL_ABS[@]}"; do
        echo "  - $p"
    done
    echo "Prefer relative paths from \$CLAUDE_PROJECT_DIR (=${CLAUDE_PROJECT_DIR:-pwd}) when possible. This is a nudge, not a block — the command will run."
fi

exit 0
