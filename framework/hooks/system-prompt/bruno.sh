#!/usr/bin/env bash
# SessionStart hook — injects Bruno's framework reminders into every session.
# Output to stdout (with exit 0) becomes context in Bruno's first turn.
set -euo pipefail

# Discard the JSON event input — we don't need it; we always inject the same block.
cat >/dev/null

# --- OS detection (for shell-discipline reminder per CLAUDE.md §16) ---
if [[ -n "${OS:-}" && "${OS}" == "Windows_NT" ]] || [[ "${OSTYPE:-}" == "msys"* ]] || [[ "${OSTYPE:-}" == "cygwin"* ]]; then
    DETECTED_OS="Windows"
    SHELL_TOOL="PowerShell"
    PATH_STYLE='C:\Users\<user>\... (Windows form)'
    AVOID_STYLE='/c/Users/<user>/... (bash form — DO NOT USE)'
elif [[ "${OSTYPE:-}" == "darwin"* ]]; then
    DETECTED_OS="macOS"
    SHELL_TOOL="Bash"
    PATH_STYLE='/Users/<user>/... (POSIX form)'
    AVOID_STYLE='C:\... (Windows form)'
else
    DETECTED_OS="Linux"
    SHELL_TOOL="Bash"
    PATH_STYLE='/home/<user>/... (POSIX form)'
    AVOID_STYLE='C:\... (Windows form)'
fi

# Emit OS-aware shell-discipline reminder first
cat <<EOF
**Shell discipline reminder (CLAUDE.md §16):**

- Detected OS: **$DETECTED_OS**
- Use the **$SHELL_TOOL** tool exclusively for all shell operations this session.
- Use paths in $PATH_STYLE.
- AVOID: $AVOID_STYLE
- Never mix path styles within a session. Subagents inherit the same shell choice.
EOF

# Static framework reminders (OS-independent)
cat <<'EOF'

**Bruno framework reminders (injected on session start):**

- **Three-doc discipline (CLAUDE.md §7):** every PR that changes a documented fact (path, env var, schema field, CLI command, integration contract) must update REQUIREMENTS.md / DESIGN.md / PLAN.md / per-project CLAUDE.md in the SAME commit. No "doc fix in a follow-up PR" exceptions.

- **Doc verification before planning (CLAUDE.md §1):** before writing REQUIREMENTS.md, DESIGN.md, or PLAN.md for any project, verify the official upstream docs for every external integration (claude-agent-sdk, Google Drive, Notion, Discord, OAuth providers, MCP servers, etc.). Cite the version you verified against in DESIGN.md §Lifecycles. If you cannot find authoritative docs for an integration, **surface to the operator BEFORE writing PLAN.md / DESIGN.md** — do not write from memory.

- **Brief discipline (§6):** subagent briefs are pointer + delta, not standalone. Default cap: 40 lines. Cite REQUIREMENTS / DESIGN sections rather than restating them. Coder reads the canonical sources.

- **Sandbox-block = red (§3):** when a subagent reports a gate as "skipped — sandbox blocked", treat it as `local_checks_failed: [sandbox_block]`, never as silent pass. Defer to CI as the authoritative gate.

- **Debugger auto-invoke (§6, pipeline.md):** any operator-reported error output (stack trace, journalctl excerpt, failing test summary, log fragment) defaults to spawning `debugger` with the log paths, NOT diagnosing inline. Inline diagnosis is permitted only for 1-line obvious mistakes or debugger follow-up.

- **Use system Explore (§6):** for codebase exploration, use the Claude Code system `Explore` agent (capital E). The custom `explorer` was retired.

- **Senior-reviewer before operator testing (§6, pipeline.md):** before asking the operator to test, exercise, or verify a feature/PR, auto-invoke `senior-reviewer` first. Senior-reviewer creates an explicit checklist grounded in REQUIREMENTS / DESIGN / PLAN, validates against it, and surfaces the checklist + verdict to the operator. The operator's test is the LAST step, not the first.

- **Sync gate after coder (§6, pipeline.md):** after a coder returns, relay its `summary_for_operator` to the operator BEFORE invoking reviewer. Catches off-spec work early.

- **Doc-drift = release blocker (§7):** senior-reviewer treats any doc-vs-code drift as BLOCKER, never LOOSE END. Don't ship with known drift.

- **Requirements interview on main agent (§6, pipeline.md, requirements.md):** the requirements interview is **main-agent work** — no subagent. Brief-first, turn-by-turn Q&A, writes `docs/REQUIREMENTS.md` incrementally. Three trigger modes: `/new-project` (`fresh`), `/new-phase` (`new-phase` — adds Phase N+1 to existing §11 Phase Log + §1-10 deltas; procedure in `commands/new-phase.md`), and operator-requested focused updates on specific sections (`focused-update`). For existing-project flows where intent is unclear, ask: focused-update, new-phase, or full re-interview? Surface REQUIREMENTS.md + TBD list for operator approval BEFORE authoring DESIGN.md or PLAN.md (or their deltas).
EOF
