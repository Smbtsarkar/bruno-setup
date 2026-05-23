#!/usr/bin/env bash
# PreToolUse hook — matcher: Edit|Write
# Hard-blocks Write/Edit operations on paths outside ~/workspace-bruno/.
#
# This is the load-bearing constraint for the workspace-bruno blast-radius model
# (master CLAUDE.md workspace section / workspace.md). Reads can be broad; writes must stay inside the workspace.
#
# Exceptions (writes allowed despite being outside workspace):
#   - None at the framework layer. Project-specific exceptions (e.g. a project writing
#     to /etc/<project>/ via setup.sh) are Bash invocations, not Write/Edit tool calls.

set -euo pipefail

INPUT=$(cat)

if ! command -v jq >/dev/null 2>&1; then
    # Degrade gracefully — without jq we can't parse; let other layers catch it
    echo "WARN: workspace-write-block.sh requires jq; skipping." >&2
    exit 0
fi

FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
[[ -z "$FILE_PATH" ]] && exit 0

WORKSPACE_ROOT="${CLAUDE_WORKSPACE_ROOT:-$HOME/workspace-bruno}"

# Resolve symlinks if possible to catch escape via symlink
if command -v realpath >/dev/null 2>&1; then
    RESOLVED=$(realpath -m "$FILE_PATH" 2>/dev/null || echo "$FILE_PATH")
    WORKSPACE_RESOLVED=$(realpath -m "$WORKSPACE_ROOT" 2>/dev/null || echo "$WORKSPACE_ROOT")
else
    RESOLVED="$FILE_PATH"
    WORKSPACE_RESOLVED="$WORKSPACE_ROOT"
fi

# Allow writes inside the workspace
if [[ "$RESOLVED" == "$WORKSPACE_RESOLVED" || "$RESOLVED" == "$WORKSPACE_RESOLVED/"* ]]; then
    exit 0
fi

# Block writes outside
echo "workspace-write-block.sh BLOCKED the write:" >&2
echo "" >&2
echo "  Tool path: $FILE_PATH" >&2
echo "  Resolved:  $RESOLVED" >&2
echo "  Workspace: $WORKSPACE_RESOLVED" >&2
echo "" >&2
echo "Per master CLAUDE.md workspace section, Write/Edit operations are confined to the Bruno workspace" >&2
echo "(\$CLAUDE_WORKSPACE_ROOT or ~/workspace-bruno/ by default). This file is outside." >&2
echo "" >&2
echo "If this write is operationally necessary (e.g. seeding /etc/<service>/ during install)," >&2
echo "do it via Bash (cat > ..., tee, etc.) — those go through other gates and audit." >&2
echo "" >&2
echo "If this file should logically be inside the workspace, move the project under" >&2
echo "~/workspace-bruno/ and retry." >&2
exit 2
