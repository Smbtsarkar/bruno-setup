#!/usr/bin/env bash
# Stop hook
# At end of turn, check if any tasks are still in_progress. If yes, inject a
# reminder context for the next turn.

set -euo pipefail

INPUT=$(cat)

if ! command -v jq >/dev/null 2>&1; then
    exit 0
fi

# The Stop event provides .session_id which we could use to query the task store,
# but the task store is internal to Claude Code. We can check for the harness's
# task-tracking file if it exists at a known location, or fall back to a best-effort
# session-id-keyed scan under $HOME/AppData/Local/Temp/claude/.

SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')
[[ -z "$SESSION_ID" ]] && exit 0

# Look for a tasks file under any common temp location
TEMP_BASES=(
    "$HOME/AppData/Local/Temp/claude"
    "${TMPDIR:-}/claude"
    "/tmp/claude"
)

TASK_FILE=""
for base in "${TEMP_BASES[@]}"; do
    [[ -z "$base" ]] && continue
    [[ ! -d "$base" ]] && continue
    # `find | head -1` under set -euo pipefail can trip pipefail if find errors
    # mid-scan — wrap in `|| true` so a partial scan doesn't kill the hook.
    candidate=$( { find "$base" -name "tasks.json" 2>/dev/null || true; } | head -1)
    if [[ -n "$candidate" ]]; then
        TASK_FILE="$candidate"
        break
    fi
done

# If we can't find a task file, exit silently — this hook is best-effort
if [[ -z "$TASK_FILE" || ! -f "$TASK_FILE" ]]; then
    exit 0
fi

# Count in_progress tasks
IN_PROGRESS_COUNT=$(jq '[.tasks[]? | select(.status == "in_progress")] | length' "$TASK_FILE" 2>/dev/null || echo 0)

if [[ "$IN_PROGRESS_COUNT" -gt 0 ]]; then
    IN_PROGRESS_SUBJECTS=$(jq -r '.tasks[]? | select(.status == "in_progress") | "  - " + .subject' "$TASK_FILE" 2>/dev/null || echo "")

    cat <<EOF
**Task hygiene reminder (task-stale-on-stop hook):**

$IN_PROGRESS_COUNT task(s) still in_progress at end of turn:
$IN_PROGRESS_SUBJECTS

Either complete them, mark as blocked, or remove if obsolete before the next turn.
Stale in-progress tasks accumulate as context noise.
EOF
fi

exit 0
