#!/usr/bin/env bash
# SubagentStart hook — matcher: reviewer
set -euo pipefail

cat >/dev/null

# OS detection for shell-discipline (CLAUDE.md §25)
if [[ -n "${OS:-}" && "${OS}" == "Windows_NT" ]] || [[ "${OSTYPE:-}" == "msys"* ]] || [[ "${OSTYPE:-}" == "cygwin"* ]]; then
    _SHELL_REMINDER="**Shell discipline (CLAUDE.md §25):** OS=Windows. Use the **PowerShell** tool exclusively (NOT Bash). Paths in C:\Users\<user>\... form. Inherits from Bruno session."
elif [[ "${OSTYPE:-}" == "darwin"* ]]; then
    _SHELL_REMINDER="**Shell discipline (CLAUDE.md §25):** OS=macOS. Use the **Bash** tool exclusively. Paths in /Users/<user>/... form."
else
    _SHELL_REMINDER="**Shell discipline (CLAUDE.md §25):** OS=Linux. Use the **Bash** tool exclusively. Paths in /home/<user>/... form."
fi
echo "$_SHELL_REMINDER"
echo ""


cat <<'EOF'
**Reviewer reminders (injected on agent start):**

- **Pin your gate environment to CI's** before running any gate command. Export `NO_COLOR=1`, `FORCE_COLOR=0` (or matching CI), `TERM=dumb`, OR run inside the CI container image. Document what you pinned in Shape A's `gate_environment` field — it is MANDATORY. Reviewer-passes-CI-fails happens when environments diverge (rich-rendered ANSI is the canonical example).

- **Run `ruff format --check` explicitly** (or the stack equivalent). `ruff check` alone does NOT cover format violations. Several PRs in past releases slipped because format-check was skipped at the reviewer layer.

- **Comprehensive mode requires adjacent-surface scan** (master CLAUDE.md §8). For the bug or feature this PR addresses, identify the root-cause class (not just the symptom) and scan for adjacent sites that may have the same defect. Output goes into Shape A's `adjacent_surfaces_scanned` field. Empty/skip is NOT allowed — if there's no root-cause class to scan for, say so explicitly.

- **Doc-drift = BLOCKING deviation** (master CLAUDE.md §17). If the PR changes a documented fact (path, command, schema, integration contract), verify the corresponding doc update is in the SAME diff. Missing doc update → blocking deviation, not a follow-up.

- **Mock-contract check.** Any new mock of an external client must enforce the protocol contract (connect-before-query, init-before-use). Mocks without contract enforcement are LOOSE END at minimum, BLOCKING if the gap is known to crash production.

- **Sandbox-block = Shape B, not silent pass.** If your gate can't run in this environment, return Shape B with `local_checks_failed: [sandbox_block]`. Main Claude will either re-spawn you in a different env or open the PR with CI as the authoritative gate.

- **Don't edit code.** Not even a trivial typo. Bounce it. The boundary keeps roles clean.

- **You don't merge.** Open PRs only when clean. Main Claude merges after operator approval.

- **PR body MUST include `### How to verify (operator-runs-this)`** — concrete pasteable commands an operator can run on a clean VM. Not "run the test suite" — that's the gate's job. This is the operator-simulation section.
EOF
