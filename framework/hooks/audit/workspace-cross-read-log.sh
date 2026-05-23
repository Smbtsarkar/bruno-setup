#!/usr/bin/env bash
# PostToolUse hook — matcher: Read|Glob|Grep
# Logs Bruno tool calls that read paths outside ~/workspace-bruno/.
# Audit only — does not block. Reads are permitted; the log gives forensics.

set -euo pipefail

INPUT=$(cat)

if ! command -v jq >/dev/null 2>&1; then
    exit 0
fi

TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')

# Extract the path arg based on tool
case "$TOOL_NAME" in
    Read)
        TARGET=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
        ;;
    Glob)
        TARGET=$(echo "$INPUT" | jq -r '.tool_input.path // .tool_input.pattern // empty')
        ;;
    Grep)
        TARGET=$(echo "$INPUT" | jq -r '.tool_input.path // empty')
        ;;
    *)
        exit 0
        ;;
esac

[[ -z "$TARGET" ]] && exit 0

WORKSPACE_ROOT="${CLAUDE_WORKSPACE_ROOT:-$HOME/workspace-bruno}"

# Resolve and check if outside workspace
if command -v realpath >/dev/null 2>&1; then
    RESOLVED=$(realpath -m "$TARGET" 2>/dev/null || echo "$TARGET")
    WORKSPACE_R=$(realpath -m "$WORKSPACE_ROOT" 2>/dev/null || echo "$WORKSPACE_ROOT")
else
    RESOLVED="$TARGET"
    WORKSPACE_R="$WORKSPACE_ROOT"
fi

# Inside workspace? Don't log
if [[ "$RESOLVED" == "$WORKSPACE_R" || "$RESOLVED" == "$WORKSPACE_R/"* ]]; then
    exit 0
fi

# Skip logging for framework reads — those are normal operations
if [[ "$RESOLVED" == "$HOME/.claude" || "$RESOLVED" == "$HOME/.claude/"* ]]; then
    exit 0
fi

# Skip logging for clearly-system reads that we expect (OS detection, etc.)
case "$RESOLVED" in
    /etc/os-release|/etc/lsb-release|/etc/hostname|/proc/*|/sys/*)
        exit 0
        ;;
esac

# Log the cross-workspace read
LOG_DIR="$HOME/.claude/audit"
mkdir -p "$LOG_DIR"
LOG_FILE="$LOG_DIR/cross-workspace-reads.log"

TIMESTAMP=$(date -u +%Y-%m-%dT%H:%M:%SZ)
USER_NAME=$(whoami 2>/dev/null || echo "unknown")
PROJECT=$(basename "${CLAUDE_PROJECT_DIR:-unknown}")

printf '%s\t%s\t%s\t%s\t%s\n' \
    "$TIMESTAMP" "$USER_NAME" "$PROJECT" "$TOOL_NAME" "$RESOLVED" \
    >> "$LOG_FILE"

# Silent — audit only
exit 0
