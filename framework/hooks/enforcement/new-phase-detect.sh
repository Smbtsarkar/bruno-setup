#!/usr/bin/env bash
# UserPromptSubmit hook
# Detects /new-phase and !new-phase patterns in the user prompt and
# injects context for Bruno to run the new-phase flow (read existing
# REQUIREMENTS.md, infer next phase number, prompt for phase-tagged brief,
# focused delta interview, approval gate, then DESIGN/PLAN deltas).
#
# /new-phase — Claude Code CLI slash command; handled natively by the CLI.
#              This hook still detects the text form for non-CLI interfaces
#              (e.g. Discord channels routed through a harness) where the
#              slash command isn't intercepted by the CLI.
# !new-phase — Text-pattern form. Detected here. Works in any text interface.

set -euo pipefail

INPUT=$(cat)

if ! command -v jq >/dev/null 2>&1; then
    exit 0
fi

PROMPT=$(echo "$INPUT" | jq -r '.prompt // empty')
[[ -z "$PROMPT" ]] && exit 0

CWD=$(echo "$INPUT" | jq -r '.cwd // empty')
[[ -z "$CWD" ]] && CWD="$PWD"

# Match /new-phase or !new-phase (no name argument required)
if ! echo "$PROMPT" | grep -qE '(^|[[:space:]])[/!]new-phase(\s|$)'; then
    exit 0
fi

REQ_PATH="$CWD/docs/REQUIREMENTS.md"

# Validate: REQUIREMENTS.md must exist in the current project
if [[ ! -f "$REQ_PATH" ]]; then
    cat <<EOF
**New-phase request detected (master CLAUDE.md §6 / pipeline.md):**

Pattern: \`$(echo "$PROMPT" | grep -oE '[/!]new-phase' | head -1)\`

**Cannot proceed: \`$REQ_PATH\` does not exist.**

\`/new-phase\` extends an existing project's REQUIREMENTS.md. This directory has no requirements doc, which means either:
- The project was never initialized via \`/new-project\` — run that first.
- You're in the wrong directory — \`cd\` into the project root.

Tell the operator which case applies and ask how to proceed. Do NOT create REQUIREMENTS.md from scratch via \`/new-phase\` — that's \`/new-project\`'s job.
EOF
    exit 0
fi

# Infer the highest existing phase number from REQUIREMENTS.md.
# Patterns scanned (case-insensitive):
#   - "# Phase N:" / "## Phase N" / "### Phase N" headings
#   - "Phase N" in BRIEF markers
#   - "CAP-N." capability prefix (if the project uses phase-tagged CAP IDs)
HIGHEST=$(grep -oiE '(\#+\s*phase\s+[0-9]+|phase\s+[0-9]+|cap-[0-9]+\.[0-9]+)' "$REQ_PATH" \
    | grep -oE '[0-9]+' \
    | sort -nr \
    | head -1 \
    || true)

if [[ -z "$HIGHEST" ]]; then
    # No phase references at all → existing REQUIREMENTS.md is implicitly Phase 1
    INFERRED_CURRENT=1
    BOOTSTRAP_NEEDED="yes (no §11 Phase Log; treat existing REQUIREMENTS.md as Phase 1 baseline)"
else
    INFERRED_CURRENT="$HIGHEST"
    if grep -qE '^##\s+11\.\s+Phase\s+Log' "$REQ_PATH"; then
        BOOTSTRAP_NEEDED="no (§11 Phase Log already present)"
    else
        BOOTSTRAP_NEEDED="yes (§11 Phase Log section missing; create it before appending Phase $((INFERRED_CURRENT + 1)))"
    fi
fi

NEXT_PHASE=$((INFERRED_CURRENT + 1))

# Branch + working-tree pre-flight
BRANCH=$(cd "$CWD" && git rev-parse --abbrev-ref HEAD 2>/dev/null || echo "unknown")
DIRTY="no"
if cd "$CWD" 2>/dev/null && [[ -n "$(git status --porcelain 2>/dev/null)" ]]; then
    DIRTY="yes"
fi

cat <<EOF
**New-phase request detected (master CLAUDE.md §6 / pipeline.md):**

- Pattern: \`$(echo "$PROMPT" | grep -oE '[/!]new-phase' | head -1)\`
- Project root: \`$CWD\`
- REQUIREMENTS.md: \`$REQ_PATH\` (exists)
- Highest existing phase detected: **Phase $INFERRED_CURRENT**
- Next phase will be: **Phase $NEXT_PHASE**
- §11 Phase Log bootstrap needed: $BOOTSTRAP_NEEDED
- Current git branch: \`$BRANCH\`
- Working tree dirty: $DIRTY

Per the new-phase flow (\`framework/commands/new-phase.md\`, \`framework/docs/requirements.md\` §2 new-phase mode):

1. **Pre-flight:**
   - If working tree is dirty, stop: "Uncommitted changes detected. Commit or stash first, then re-run \`/new-phase\`."
   - Branch handling:
     - \`master\` / \`dev\` → you'll auto-create \`feat/phase-$NEXT_PHASE-<slug>\` in step 5 (after the brief gives you a short title).
     - Any other branch → ask the operator: "Currently on \`$BRANCH\`. Create new \`feat/phase-$NEXT_PHASE-<slug>\` from \`dev\`, or stay on this branch?"
2. **Confirm Phase $NEXT_PHASE** with the operator. Wait for explicit y/yes/proceed before any branch creation or file edits.
3. **Ask for the phase-tagged brief** verbatim: *"Brief for Phase $NEXT_PHASE — what does this phase add, change, or cut? Free text. Please mark with \`# Phase $NEXT_PHASE:\` at the top so we record the right phase number."* — **do not write to any file yet**; the brief lives in memory until step 5.
4. **Extract the short title** from the brief (3–6 word summary). Ask one focused follow-up if it isn't clear.
5. **Create the feature branch** (if not staying on current): derive \`<slug>\` from the short title (lowercase, non-alphanumeric → \`-\`, collapse \`-\`, ≤40 chars), then \`git checkout dev && git pull --ff-only origin dev && git checkout -b feat/phase-$NEXT_PHASE-<slug>\`. Surface the new branch name to the operator. If any git step fails, stop and surface the error — do NOT edit REQUIREMENTS.md on master/dev.
6. **Bootstrap §11 Phase Log** if missing (now on the feature branch). Capture the original \`<!-- BRIEF: ... -->\` as Phase 1 inside the new §11.
7. **Append \`### Phase $NEXT_PHASE\`** with the verbatim brief as \`<!-- BRIEF (Phase $NEXT_PHASE): ... -->\`.
8. **Run the focused delta interview** — only ask about REQUIREMENTS sections this phase touches (per requirements.md §5 question script, scoped to deltas). Update §1–§10 in place AND update the §11.Phase $NEXT_PHASE delta summary in parallel.
9. **Approval gate** (per requirements.md §8): surface the delta summary + TBDs + branch name, ask the operator to approve before authoring DESIGN.md deltas (only if lifecycles/sources-of-truth changed) and PLAN.md deltas (new \`## Phase $NEXT_PHASE\` section).
10. **No \`scaffolder\`** for new-phase — the project is already scaffolded. After approval, the standard pipeline resumes with \`coder\` for Phase $NEXT_PHASE.

Do NOT author DESIGN.md or PLAN.md deltas before the operator approves Phase $NEXT_PHASE in REQUIREMENTS.md. The approval gate is load-bearing — same as \`/new-project\`.
EOF
