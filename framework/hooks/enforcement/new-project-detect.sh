#!/usr/bin/env bash
# UserPromptSubmit hook
# Detects /new-project and !new-project patterns in the user prompt and
# injects context for Bruno to run the new-project flow (requirements
# interview on main agent, then DESIGN/PLAN on operator approval).
#
# /new-project — Claude Code CLI slash command; handled natively by the CLI.
#                This hook still detects the text form for non-CLI interfaces
#                (e.g. Discord channels routed through a harness) where the
#                slash command isn't intercepted by the CLI.
# !new-project — Text-pattern form. Detected here. Works in any text interface.

set -euo pipefail

INPUT=$(cat)

if ! command -v jq >/dev/null 2>&1; then
    exit 0
fi

PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty')
[[ -z "$PROMPT" ]] && exit 0

# Match /new-project <name> or !new-project <name>
# Capture the project name (alphanumeric, dash, underscore)
TARGET=$(echo "$PROMPT" | grep -oP '(?:^|[[:space:]])[/!]new-project[[:space:]]+\K[a-zA-Z0-9_-]+' | head -1 || true)

[[ -z "$TARGET" ]] && exit 0

WORKSPACE_ROOT="${CLAUDE_WORKSPACE_ROOT:-$HOME/workspace-bruno}"
TARGET_PATH="$WORKSPACE_ROOT/$TARGET"

# Build the context block
TARGET_EXISTS="no"
TARGET_IS_EMPTY="n/a"
TARGET_IS_GIT="no"

if [[ -d "$TARGET_PATH" ]]; then
    TARGET_EXISTS="yes"
    if [[ -z "$(ls -A "$TARGET_PATH" 2>/dev/null)" ]]; then
        TARGET_IS_EMPTY="yes"
    else
        TARGET_IS_EMPTY="no"
    fi
    [[ -d "$TARGET_PATH/.git" ]] && TARGET_IS_GIT="yes"
fi

cat <<EOF
**New project request detected (master CLAUDE.md §6 / pipeline.md):**

- Pattern: \`$(echo "$PROMPT" | grep -oE '[/!]new-project[[:space:]]+[a-zA-Z0-9_-]+' | head -1)\`
- Target: \`$TARGET\`
- Target path: \`$TARGET_PATH\`

Validation:
- Target directory exists: $TARGET_EXISTS
- Target directory is empty: $TARGET_IS_EMPTY
- Target is a git repo already: $TARGET_IS_GIT

Per the bootstrap flow:
1. Confirm the new-project target with the operator (especially if the directory exists and is non-empty).
2. Create \`$TARGET_PATH\` if missing.
3. Run the requirements interview yourself per \`~/.claude/docs/requirements.md\` — mode: fresh. Your FIRST turn asks the operator for a brief, then turn-by-turn Q&A, writing \`docs/REQUIREMENTS.md\` incrementally.
4. Surface the populated REQUIREMENTS.md + TBD list for operator approval (per requirements.md §8).
5. ONLY on approval: author DESIGN.md (if external integrations declared) and PLAN.md.
6. Invoke \`scaffolder\` with the approved docs.

Do NOT scaffold, write DESIGN.md, write PLAN.md, or invoke coder/reviewer before the operator approves REQUIREMENTS.md. Requirements approval is the load-bearing gate.

If the target directory exists and is non-empty, stop and ask the operator how to proceed (overwrite, pick a different name, etc.) before starting the interview.
EOF
