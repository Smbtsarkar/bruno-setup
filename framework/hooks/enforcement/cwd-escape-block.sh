#!/usr/bin/env bash
# CwdChanged hook
# Blocks CWD changes that land outside the project root.

set -euo pipefail

INPUT=$(cat)

if ! command -v jq >/dev/null 2>&1; then
    exit 0
fi

NEW_CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
[[ -z "$NEW_CWD" ]] && exit 0

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"

# Resolve symlinks for both paths
if command -v realpath >/dev/null 2>&1; then
    NEW_CWD_RESOLVED=$(realpath -m "$NEW_CWD" 2>/dev/null || echo "$NEW_CWD")
    PROJECT_DIR_RESOLVED=$(realpath -m "$PROJECT_DIR" 2>/dev/null || echo "$PROJECT_DIR")
else
    NEW_CWD_RESOLVED="$NEW_CWD"
    PROJECT_DIR_RESOLVED="$PROJECT_DIR"
fi

# Allow if new CWD is the project dir or a descendant
if [[ "$NEW_CWD_RESOLVED" == "$PROJECT_DIR_RESOLVED" || "$NEW_CWD_RESOLVED" == "$PROJECT_DIR_RESOLVED/"* ]]; then
    exit 0
fi

# Also allow if new CWD is under $HOME/.claude (framework operations)
if [[ "$NEW_CWD_RESOLVED" == "$HOME/.claude" || "$NEW_CWD_RESOLVED" == "$HOME/.claude/"* ]]; then
    exit 0
fi

# Block
echo "cwd-escape-block.sh BLOCKED CWD change:" >&2
echo "" >&2
echo "  From: $PROJECT_DIR_RESOLVED" >&2
echo "  To:   $NEW_CWD_RESOLVED" >&2
echo "" >&2
echo "Refusing CWD change outside \$CLAUDE_PROJECT_DIR. Use absolute paths in tool args" >&2
echo "instead of changing CWD. If you genuinely need to operate from a different repo," >&2
echo "escalate to the operator — that's a /switch-project flow, not a mid-session cd." >&2
exit 2
