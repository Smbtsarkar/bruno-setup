#!/usr/bin/env bash
# CwdChanged hook
# Allows cd within the workspace; blocks cd outside the workspace root.
# Within the workspace, cd to a SIBLING project (different sub-folder of workspace)
# is allowed only via the /switch-project or !switch-project flow — this hook
# refuses bare cd between projects to enforce the operator-approval gate.

set -euo pipefail

INPUT=$(cat)

if ! command -v jq >/dev/null 2>&1; then
    exit 0
fi

NEW_CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
[[ -z "$NEW_CWD" ]] && exit 0

WORKSPACE_ROOT="${CLAUDE_WORKSPACE_ROOT:-$HOME/workspace-bruno}"
PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"

# Resolve symlinks
if command -v realpath >/dev/null 2>&1; then
    NEW_CWD_R=$(realpath -m "$NEW_CWD" 2>/dev/null || echo "$NEW_CWD")
    WORKSPACE_R=$(realpath -m "$WORKSPACE_ROOT" 2>/dev/null || echo "$WORKSPACE_ROOT")
    PROJECT_R=$(realpath -m "$PROJECT_DIR" 2>/dev/null || echo "$PROJECT_DIR")
else
    NEW_CWD_R="$NEW_CWD"
    WORKSPACE_R="$WORKSPACE_ROOT"
    PROJECT_R="$PROJECT_DIR"
fi

# Allow cd within the current project (same root)
if [[ "$NEW_CWD_R" == "$PROJECT_R" || "$NEW_CWD_R" == "$PROJECT_R/"* ]]; then
    exit 0
fi

# Allow cd under ~/.claude/ (framework operations)
if [[ "$NEW_CWD_R" == "$HOME/.claude" || "$NEW_CWD_R" == "$HOME/.claude/"* ]]; then
    exit 0
fi

# Inside the workspace but DIFFERENT project — that's a project switch attempt
if [[ "$NEW_CWD_R" == "$WORKSPACE_R" || "$NEW_CWD_R" == "$WORKSPACE_R/"* ]]; then
    echo "cwd-escape-block.sh BLOCKED a project switch:" >&2
    echo "" >&2
    echo "  From: $PROJECT_R" >&2
    echo "  To:   $NEW_CWD_R" >&2
    echo "" >&2
    echo "Both are inside the workspace ($WORKSPACE_R) but are DIFFERENT projects." >&2
    echo "Project switching requires the explicit /switch-project flow (master CLAUDE.md workspace section / workspace.md):" >&2
    echo "" >&2
    echo "  /switch-project <name>    (Claude Code CLI slash command)" >&2
    echo "  !switch-project <name>    (text pattern, works in any channel)" >&2
    echo "" >&2
    echo "Use one of those so the operator can approve the switch." >&2
    exit 2
fi

# Outside the workspace entirely
echo "cwd-escape-block.sh BLOCKED CWD change outside workspace:" >&2
echo "" >&2
echo "  From:      $PROJECT_R" >&2
echo "  To:        $NEW_CWD_R" >&2
echo "  Workspace: $WORKSPACE_R" >&2
echo "" >&2
echo "Refusing CWD change outside the Bruno workspace. Use absolute paths in tool args" >&2
echo "instead of changing CWD. If you need to operate on a different workspace project," >&2
echo "use /switch-project <name> or !switch-project <name>." >&2
exit 2
