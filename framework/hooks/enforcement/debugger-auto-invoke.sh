#!/usr/bin/env bash
# UserPromptSubmit hook
# Detects error-output patterns in the user's prompt; if found, injects context
# reminding Bruno to spawn debugger rather than diagnose inline.

set -euo pipefail

INPUT=$(cat)

if ! command -v jq >/dev/null 2>&1; then
    exit 0
fi

# The user prompt is in .prompt for UserPromptSubmit events
PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty')
[[ -z "$PROMPT" ]] && exit 0

# Error-output patterns to detect
PATTERNS=(
    'Traceback \(most recent call last\)'
    'journalctl -u'
    'systemd\[[0-9]+\]:'
    '\[ERROR\]'
    '\[FATAL\]'
    '\[CRITICAL\]'
    'Error: '
    'ERROR '
    'Failed '
    'FAILED '
    'failed with exit code'
    'non-zero exit'
    'exit code [1-9]'
    'Exception in thread'
    'panicked at'
    'segmentation fault'
    'core dumped'
    '\bat .*:.*:[0-9]+\)'              # JS stack frames
    'Caused by:'                       # Java/Rust nested errors
    'OSError|RuntimeError|ValueError|KeyError|TypeError|ImportError|FileNotFoundError'
    'Permission denied'
    'No such file or directory'
)

MATCHED=()
for pattern in "${PATTERNS[@]}"; do
    if echo "$PROMPT" | grep -qE "$pattern"; then
        MATCHED+=("$pattern")
    fi
done

if [[ ${#MATCHED[@]} -gt 0 ]]; then
    cat <<EOF
**Debugger reminder (injected by debugger-auto-invoke hook):**

The operator's message contains error-output patterns:
$(printf '  - %s\n' "${MATCHED[@]}")

Per master CLAUDE.md §8 (Debugger auto-invoke), spawn the \`debugger\` subagent with
the log path/fetch command rather than reading and diagnosing inline. Inline diagnosis
is permitted ONLY when:
  (a) The failure is a 1-line obvious mistake from current conversation context, OR
  (b) Debugger has already run on this specific failure and you're following up.

If you must diagnose inline (per (a) or (b) above), say so explicitly so the operator
knows you intentionally bypassed the debugger path. Otherwise, spawn debugger with the
relevant log path/command and any reproduction step.

Reading 30 lines of pasted error output in the main agent's foreground burns context
that should go to orchestration. Debugger has its own context window for log analysis.
EOF
fi

exit 0
