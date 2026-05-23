#!/usr/bin/env bash
# PreToolUse hook — matcher: Bash
# Runs FIRST in the Bash PreToolUse chain.
#
# Defense-in-depth layer for shell-escape patterns that permission glob matching
# might miss when commands are compound (&&, ||, ;, |, &), use command substitution
# ($(...), backticks), or have unusual whitespace.
#
# Procedure:
#   1. Read tool_input.command from stdin JSON
#   2. Extract subshell contents from $(...) and `...`
#   3. Split the command into chunks on shell separators
#   4. Apply regex patterns for forbidden ops to each chunk
#   5. Block (exit 2 + stderr) on match, or exit 0 to allow
#
# Limitations: bash grammar is too rich for regex to parse fully. This covers the
# 99% case of common attack patterns. Truly adversarial commands using heredocs,
# extensive escaping, or parameter-expansion tricks can in principle slip through.
# That's why this is one layer among many (permissions.deny, system-prompt
# reminders, sandboxing) — defense-in-depth, not a perfect wall.

set -euo pipefail

# --- Parse stdin JSON ---
INPUT=$(cat)

if ! command -v jq >/dev/null 2>&1; then
    # jq not available — surface a warning but don't block (degrade gracefully)
    echo "WARN: compound-command-check.sh requires jq; skipping defense-in-depth check. Install jq for full enforcement." >&2
    exit 0
fi

COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if [[ -z "$COMMAND" ]]; then
    # No command to check
    exit 0
fi

# --- Extract subshell contents ($(...) and `...`) and append to the command string
#     so subshell contents get pattern-matched too. ---
SUBSHELL_CONTENT=""

# $() substitution: extract everything inside $( )
while IFS= read -r match; do
    [[ -n "$match" ]] && SUBSHELL_CONTENT+=" ; $match"
done < <(echo "$COMMAND" | grep -oP '\$\(\K[^)]+(?=\))' || true)

# Backtick substitution: extract everything inside ` `
# shellcheck disable=SC2016  # the backticks here are LITERAL (regex pattern), not command substitution
while IFS= read -r match; do
    [[ -n "$match" ]] && SUBSHELL_CONTENT+=" ; $match"
done < <(echo "$COMMAND" | grep -oP '`\K[^`]+(?=`)' || true)

# Append extracted subshell content to the command for full-string matching
FULL_COMMAND="$COMMAND$SUBSHELL_CONTENT"

# --- Split on shell separators: && || ; | & ---
# We use a simple sed transformation to put each chunk on its own line.
CHUNKS=$(echo "$FULL_COMMAND" | sed -E 's/(&&|\|\||;|\|&|\||&)/\n/g')

# --- Forbidden patterns (regex applied per chunk) ---
# Each entry: PATTERN|HUMAN_DESCRIPTION
FORBIDDEN_PATTERNS=(
    '\b(rm|unlink)\s+-[rRf]+|RECURSIVE_FORCE_DELETE'
    '\bdd\s+if=|DD_DISK_WRITE'
    '\bmkfs\b|MKFS_FORMAT'
    '\bfdisk\b|FDISK'
    '\bchmod\s+-R\s+000\b|CHMOD_R_000'
    '\b(curl|wget)\b.*\|\s*(sh|bash|zsh|ksh)\b|PIPE_TO_SHELL'
    '\beval\b|EVAL'
    '\bsource\s+(/dev/|<\()|SOURCE_PROCESS_SUBSTITUTION'
    '^\s*\.\s+(/dev/|<\()|DOT_PROCESS_SUBSTITUTION'
    '\bgit\s+push\s+(--force|-f)\b|GIT_FORCE_PUSH'
    '\bgit\s+push\s+origin\s+(master|main|dev)\b|GIT_PUSH_LONGLIVED'
    '\bgit\s+push\s+origin\s+HEAD:(master|main|dev)\b|GIT_PUSH_HEAD_LONGLIVED'
    '\bgit\s+reset\s+--hard\b|GIT_RESET_HARD'
    'ANTHROPIC_API_KEY|ANTHROPIC_API_KEY_USE'
    '\bsudo\s+(rm|dd|chmod\s+-R|chown\s+-R)\b|SUDO_DESTRUCTIVE'
)

# Canonical safe absolute paths for cd (system / well-known operational dirs)
CD_SAFE_PATHS_REGEX='^(/etc/citadel/|/var/lib/citadel/|/opt/citadel|/tmp/|/tmp$|/etc/|/var/|/usr/|/opt/|/home/|'"$HOME"'|'"${CLAUDE_PROJECT_DIR:-/nonexistent}"')'

# --- Check each chunk ---
BLOCKED_REASONS=()

while IFS= read -r chunk; do
    chunk="${chunk#"${chunk%%[![:space:]]*}"}"   # ltrim
    chunk="${chunk%"${chunk##*[![:space:]]}"}"   # rtrim
    [[ -z "$chunk" ]] && continue

    # Check forbidden patterns
    for entry in "${FORBIDDEN_PATTERNS[@]}"; do
        pattern="${entry%%|*}"
        desc="${entry##*|}"
        if echo "$chunk" | grep -qE "$pattern"; then
            BLOCKED_REASONS+=("[$desc] in chunk: \"$chunk\"")
        fi
    done

    # Check cd to absolute path outside canonical safe list
    cd_target=$(echo "$chunk" | grep -oP '\bcd\s+\K(/[^\s]+)' | head -1 || true)
    if [[ -n "$cd_target" ]]; then
        # Resolve symlinks if possible
        resolved="$cd_target"
        if command -v realpath >/dev/null 2>&1; then
            resolved=$(realpath -m "$cd_target" 2>/dev/null || echo "$cd_target")
        fi
        if ! echo "$resolved" | grep -qE "$CD_SAFE_PATHS_REGEX"; then
            BLOCKED_REASONS+=("[CD_OUT_OF_PROJECT] cd to '$cd_target' (resolved: '$resolved') not in canonical safe paths or under CLAUDE_PROJECT_DIR=${CLAUDE_PROJECT_DIR:-unset}")
        fi
    fi
done <<< "$CHUNKS"

# --- Decide ---
if [[ ${#BLOCKED_REASONS[@]} -gt 0 ]]; then
    echo "compound-command-check.sh BLOCKED the command:" >&2
    echo "" >&2
    echo "  $COMMAND" >&2
    echo "" >&2
    echo "Reasons:" >&2
    for reason in "${BLOCKED_REASONS[@]}"; do
        echo "  - $reason" >&2
    done
    echo "" >&2
    echo "If you legitimately need this operation, escalate to the operator via open_questions" >&2
    echo "rather than crafting a bypass. The deny rules + this hook are a safety net for" >&2
    echo "contracts the agent should honour; they are not obstacles to engineer around." >&2
    exit 2
fi

exit 0
