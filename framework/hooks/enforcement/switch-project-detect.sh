#!/usr/bin/env bash
# UserPromptSubmit hook
# Detects /switch-project and !switch-project patterns in the user prompt and
# injects context for Bruno to run the switch flow per master CLAUDE.md §26.
#
# /switch-project — Claude Code CLI slash command; handled natively by the CLI.
#                   This hook still detects the text form for non-CLI interfaces
#                   (e.g. Discord channels routed through a harness) where the
#                   slash command isn't intercepted by the CLI.
# !switch-project — Text-pattern form. Detected here. Works in any text interface.

set -euo pipefail

INPUT=$(cat)

if ! command -v jq >/dev/null 2>&1; then
    exit 0
fi

PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty')
[[ -z "$PROMPT" ]] && exit 0

# Match /switch-project <name> or !switch-project <name>
# Capture the project name (alphanumeric, dash, underscore)
TARGET=$(echo "$PROMPT" | grep -oP '(?:^|[[:space:]])[/!]switch-project[[:space:]]+\K[a-zA-Z0-9_-]+' | head -1 || true)

[[ -z "$TARGET" ]] && exit 0

WORKSPACE_ROOT="${CLAUDE_WORKSPACE_ROOT:-$HOME/workspace-bruno}"
TARGET_PATH="$WORKSPACE_ROOT/$TARGET"

# Build the context block
TARGET_EXISTS="no"
TARGET_IS_GIT="no"
TARGET_HAS_CLAUDE_MD="no"
TARGET_INHERITS="no"

if [[ -d "$TARGET_PATH" ]]; then
    TARGET_EXISTS="yes"
    [[ -d "$TARGET_PATH/.git" ]] && TARGET_IS_GIT="yes"
    if [[ -f "$TARGET_PATH/CLAUDE.md" ]]; then
        TARGET_HAS_CLAUDE_MD="yes"
        if head -3 "$TARGET_PATH/CLAUDE.md" | grep -q "Inherits from"; then
            TARGET_INHERITS="yes"
        fi
    fi
fi

CURRENT_PROJECT=$(basename "${CLAUDE_PROJECT_DIR:-$(pwd)}")

cat <<EOF
**Project switch request detected (master CLAUDE.md §26):**

- Pattern: \`$(echo "$PROMPT" | grep -oE '[/!]switch-project[[:space:]]+[a-zA-Z0-9_-]+' | head -1)\`
- Target: \`$TARGET\`
- Target path: \`$TARGET_PATH\`
- Current project: \`$CURRENT_PROJECT\`

Validation:
- Target directory exists: $TARGET_EXISTS
- Target is a git repo: $TARGET_IS_GIT
- Target has CLAUDE.md: $TARGET_HAS_CLAUDE_MD
- CLAUDE.md inheritance clause: $TARGET_INHERITS

Per §26, you must:
1. Surface the above validation to the operator.
2. Ask the operator to confirm the switch ("Switch from $CURRENT_PROJECT to $TARGET? [y/n]").
3. On confirmation, \`cd $TARGET_PATH\` and re-read the new project's CLAUDE.md.
4. On rejection or silence, stay in $CURRENT_PROJECT and modify nothing.

Do NOT switch without explicit operator confirmation, even if the operator's intent seems obvious. The confirmation gate is load-bearing for safety and audit.
EOF
