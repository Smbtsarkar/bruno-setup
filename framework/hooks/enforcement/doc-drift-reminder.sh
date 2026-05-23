#!/usr/bin/env bash
# PostToolUse hook — matcher: Edit|Write
# If the edited file matches doc-tracked patterns, inject a reminder to update
# REQUIREMENTS.md / DESIGN.md / per-project CLAUDE.md / README in the same commit.

set -euo pipefail

INPUT=$(cat)

if ! command -v jq >/dev/null 2>&1; then
    exit 0
fi

FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
[[ -z "$FILE_PATH" ]] && exit 0

# Doc-tracked file patterns — touching any of these often means doc updates are due.
# Patterns intentionally broad: better to nudge unnecessarily than to miss drift.
DOC_TRACKED_PATTERNS=(
    'deploy/setup\.sh$'
    'deploy/.*\.service$'
    'pyproject\.toml$'
    'package\.json$'
    'Cargo\.toml$'
    'go\.mod$'
    '/cli\.py$'
    '/cli\.ts$'
    '/config/.*\.py$'
    '/config/schema\.py$'
    '/__init__\.py$'                   # version strings live here
    '\.env\.example$'
    '\.env\.template$'
    '/config\.example\.toml$'
    'alembic/versions/.*\.py$'
    '/migrations/.*\.py$'
    '\.github/workflows/.*\.yml$'
    'scripts/dev/.*\.sh$'
)

MATCHED_PATTERNS=()
for pattern in "${DOC_TRACKED_PATTERNS[@]}"; do
    if echo "$FILE_PATH" | grep -qE "$pattern"; then
        MATCHED_PATTERNS+=("$pattern")
    fi
done

if [[ ${#MATCHED_PATTERNS[@]} -gt 0 ]]; then
    cat <<EOF
**Doc-drift reminder (injected by doc-drift-reminder hook):**

You edited \`$FILE_PATH\` — this is a doc-tracked file (matched: ${MATCHED_PATTERNS[*]}).

If this edit changed a documented fact (path, env var, schema field, CLI command,
integration contract, run/test/build command), update the corresponding canonical doc
in the SAME commit per master CLAUDE.md §7:

- **CLI command added/removed/renamed** → \`README.md\` + \`docs/REQUIREMENTS.md\` (CLI surface) + \`docs/PLAN.md\` (relevant PR).
- **Path / env var / config schema changed** → \`docs/REQUIREMENTS.md\` + \`docs/DESIGN.md\` (sources of truth).
- **External integration added/changed** → \`docs/DESIGN.md\` (lifecycle + sequence + error contract).
- **Test/lint/build/run command changed** → per-project \`CLAUDE.md\`.

No "doc fix in a follow-up PR" exceptions. Main agent's pre-merge scope check will
bounce the PR back if doc updates are missing.

This is a nudge — if no documented fact changed, ignore this reminder.
EOF
fi

exit 0
