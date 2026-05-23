#!/usr/bin/env bash
# SubagentStart hook — matcher: senior-reviewer
set -euo pipefail

cat >/dev/null

# OS detection for shell-discipline (CLAUDE.md §16)
if [[ -n "${OS:-}" && "${OS}" == "Windows_NT" ]] || [[ "${OSTYPE:-}" == "msys"* ]] || [[ "${OSTYPE:-}" == "cygwin"* ]]; then
    _SHELL_REMINDER="**Shell discipline (CLAUDE.md §16):** OS=Windows. Use the **PowerShell** tool exclusively (NOT Bash). Paths in C:\Users\<user>\... form. Inherits from Bruno session."
elif [[ "${OSTYPE:-}" == "darwin"* ]]; then
    _SHELL_REMINDER="**Shell discipline (CLAUDE.md §16):** OS=macOS. Use the **Bash** tool exclusively. Paths in /Users/<user>/... form."
else
    _SHELL_REMINDER="**Shell discipline (CLAUDE.md §16):** OS=Linux. Use the **Bash** tool exclusively. Paths in /home/<user>/... form."
fi
echo "$_SHELL_REMINDER"
echo ""


cat <<'EOF'
**Senior-Reviewer reminders (injected on agent start):**

- **Create the checklist FIRST.** Before running any gate, before reading any code, produce an explicit checklist of what you will validate. Ground every checklist item in:
  - `docs/REQUIREMENTS.md` — for capability and operator-flow coverage
  - `docs/DESIGN.md` — for lifecycle, sequence, source-of-truth, error-contract coverage
  - `docs/PLAN.md` — for PR completion and acceptance-criteria coverage
  - per-project `CLAUDE.md` — for stack-specific commands and rules
  Surface the checklist as the FIRST section of your report. The operator should see WHAT you will verify before reading the verdict.

- **You are invoked BEFORE the operator is asked to test** (master CLAUDE.md §6 / pipeline.md). Not only at release-cut time — also before any feature/PR is presented to the operator for verification. The operator's manual test is the LAST step; your validation is the second-to-last.

- **Doc-vs-code drift is BLOCKER, never LOOSE END.** Any "REQUIREMENTS / DESIGN / per-project CLAUDE.md / README says X, code does Y" finding blocks the release until reconciled. Past releases shipped with drift labelled non-blocking; that pattern is retired.

- **"Non-blocking" requires explicit operator override.** Default behaviour: any finding blocks until fixed. You do not pre-classify findings as "non-blocking" to soften the verdict — operator decides.

- **Install-walkthrough is a mandatory gate** (master CLAUDE.md §15 / deployment-gate.md). Run `scripts/dev/install-gate.sh` (or equivalent) against a clean container. If the install doesn't work end-to-end, the release is BLOCKED regardless of how green the unit tests look.

- **DESIGN.md coverage check.** For every section in DESIGN.md (§Lifecycles, §Sequences, §Sources of Truth, §Error/Recovery, §First-install vs Re-install), verify the code matches. Documented lifecycles whose methods aren't called → BLOCKER. Source-of-truth conflicts (multiple components writing the same fact) → BLOCKER.

- **Mock-contract sweep.** Find every mock of an external client. Verify each enforces the protocol contract it replaces. Mocks without contract enforcement → LOOSE END, or BLOCKER if known to crash production.

- **No verdict before the LAST check.** Walk every dimension; decide the verdict after.

- **No editorializing.** State the observation with `file:line` or verbatim output. No "obviously broken" or "looks fine" — facts only.

- **Pin gate environment to CI's** (same as reviewer) before running gates. Divergence between your env and CI's = unreliable verdict.
EOF
