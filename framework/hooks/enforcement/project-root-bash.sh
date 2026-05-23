#!/usr/bin/env bash
# PreToolUse hook — matcher: Bash
# Blocks `cd /<abs_path>` outside the project root, anywhere in a compound command.
#
# Layered with compound-command-check.sh (which catches more patterns including
# command substitution). This script focuses specifically on the cd-to-absolute-path
# pattern and provides clearer messaging for that case.

set -euo pipefail

INPUT=$(cat)

if ! command -v jq >/dev/null 2>&1; then
    echo "WARN: project-root-bash.sh requires jq; skipping check." >&2
    exit 0
fi

COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
[[ -z "$COMMAND" ]] && exit 0

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"

# Canonical safe absolute paths for cd (system / operational dirs the framework permits)
SAFE_PATHS=(
    "/etc/citadel"
    "/var/lib/citadel"
    "/opt/citadel"
    "/tmp"
    "$HOME"
    "$HOME/.claude"
    "$PROJECT_DIR"
)

# Extract every `cd /<path>` occurrence in the command (handles compound commands)
BLOCKED=()
while IFS= read -r target; do
    [[ -z "$target" ]] && continue

    # Resolve symlinks if possible to catch escape via symlink
    resolved="$target"
    if command -v realpath >/dev/null 2>&1; then
        resolved=$(realpath -m "$target" 2>/dev/null || echo "$target")
    fi

    # Check if resolved is under any safe path
    is_safe=0
    for safe in "${SAFE_PATHS[@]}"; do
        if [[ "$resolved" == "$safe" || "$resolved" == "$safe/"* ]]; then
            is_safe=1
            break
        fi
    done

    if [[ "$is_safe" -eq 0 ]]; then
        BLOCKED+=("cd '$target' (resolved: '$resolved') is not under \$CLAUDE_PROJECT_DIR ($PROJECT_DIR) or any canonical safe path")
    fi
done < <(echo "$COMMAND" | grep -oP '\bcd\s+\K(/[^\s;&|]+)' || true)

# Also check for `cd ../..` patterns (escape via relative path)
if echo "$COMMAND" | grep -qE '\bcd\s+\.\./\.\.'; then
    # Compute where that would land
    candidate_resolved=$(realpath -m "$PROJECT_DIR/../.." 2>/dev/null || echo "../..")
    if [[ "$candidate_resolved" != "$PROJECT_DIR"* ]]; then
        BLOCKED+=("cd ../.. (or deeper) escapes \$CLAUDE_PROJECT_DIR ($PROJECT_DIR)")
    fi
fi

if [[ ${#BLOCKED[@]} -gt 0 ]]; then
    echo "project-root-bash.sh BLOCKED the command:" >&2
    echo "" >&2
    echo "  $COMMAND" >&2
    echo "" >&2
    echo "Reasons:" >&2
    for reason in "${BLOCKED[@]}"; do
        echo "  - $reason" >&2
    done
    echo "" >&2
    echo "Use a relative path from \$CLAUDE_PROJECT_DIR, or pass an absolute path as" >&2
    echo "an argument to a tool (without cd) if you need to operate on a file elsewhere." >&2
    echo "Canonical safe absolute paths: ${SAFE_PATHS[*]}" >&2
    exit 2
fi

exit 0
