#!/usr/bin/env bash
# PreToolUse hook — matcher: Bash with `if: "Bash(git commit *)"`
# Blocks `git commit` if the project has a .pre-commit-config.yaml but the
# pre-commit git hook isn't installed.

set -euo pipefail

INPUT=$(cat)

if ! command -v jq >/dev/null 2>&1; then
    exit 0
fi

COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')
[[ -z "$COMMAND" ]] && exit 0

PROJECT_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"

CONFIG_FILE="$PROJECT_DIR/.pre-commit-config.yaml"
HOOK_FILE="$PROJECT_DIR/.git/hooks/pre-commit"

# Only enforce if the project declares pre-commit usage
if [[ ! -f "$CONFIG_FILE" ]]; then
    exit 0
fi

# Hook is installed?
if [[ -f "$HOOK_FILE" ]]; then
    exit 0
fi

# Hook config exists but hook not installed — block
echo "pre-commit-installed.sh BLOCKED the commit:" >&2
echo "" >&2
echo "  $COMMAND" >&2
echo "" >&2
echo "Project has .pre-commit-config.yaml at $CONFIG_FILE but the git hook is NOT installed." >&2
echo "Without it, lint/format/shellcheck checks won't run before commit — they'll be caught by CI" >&2
echo "much later and require a hotfix cycle." >&2
echo "" >&2
echo "Install once per clone:" >&2
echo "  uv run pre-commit install" >&2
echo "" >&2
echo "Then retry the commit. (If you need to bypass for a single commit, use" >&2
echo "  git commit --no-verify" >&2
echo "but expect CI to enforce the same checks at PR time.)" >&2
exit 2
