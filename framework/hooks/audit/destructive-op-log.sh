#!/usr/bin/env bash
# PostToolUse hook — matcher: Bash
# Logs destructive ops (after they ran) for forensics.

set -euo pipefail

INPUT=$(cat)

if ! command -v jq >/dev/null 2>&1; then
    exit 0
fi

COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
EXIT_CODE=$(echo "$INPUT" | jq -r '.tool_response.exit_code // empty')
[[ -z "$COMMAND" ]] && exit 0

# Patterns that count as destructive (log even if exit failed)
DESTRUCTIVE_PATTERNS=(
    '\bgit\s+push\s+(--force|-f)\b'
    '\bgit\s+reset\s+--hard\b'
    '\bgit\s+branch\s+-D\b'
    '\bgit\s+clean\s+-[fd]'
    '\b(rm|unlink)\s+-[rRf]'
    '\bgh\s+pr\s+merge\b'
    '\bgh\s+repo\s+delete\b'
    '\bgh\s+release\s+delete\b'
    '\bdd\s+if='
    '\bmkfs\b'
    '\bsystemctl\s+stop\b'
    '\bsystemctl\s+disable\b'
)

MATCHED=()
for pattern in "${DESTRUCTIVE_PATTERNS[@]}"; do
    if echo "$COMMAND" | grep -qE "$pattern"; then
        MATCHED+=("$pattern")
    fi
done

if [[ ${#MATCHED[@]} -eq 0 ]]; then
    exit 0
fi

# Determine log location: project audit dir, fall back to user dir
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
LOG_DIR=""

if [[ -d "$PROJECT_DIR/.claude" ]]; then
    LOG_DIR="$PROJECT_DIR/.claude/audit"
else
    LOG_DIR="$HOME/.claude/audit"
fi

mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/destructive-ops.log"

TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
USER_NAME=$(whoami 2>/dev/null || echo "unknown")
PATTERNS_STR=$(printf '%s,' "${MATCHED[@]}" | sed 's/,$//')

# Append one structured line (timestamp\tuser\texit\tpatterns\tcommand)
printf '%s\t%s\t%s\t[%s]\t%s\n' \
    "$TIMESTAMP" "$USER_NAME" "${EXIT_CODE:-unknown}" "$PATTERNS_STR" "$COMMAND" \
    >> "$LOG_FILE"

# Silent — audit only; don't inject context or output to operator
exit 0
