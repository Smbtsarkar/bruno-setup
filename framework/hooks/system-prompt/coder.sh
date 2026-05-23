#!/usr/bin/env bash
# SubagentStart hook — matcher: coder
# Injects coder-specific contract reminders before the agent runs.
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
**Coder reminders (injected on agent start):**

- **`summary_for_operator` is MANDATORY** in your return YAML. 2-3 lines describing what you changed and any decisions you made beyond the brief. Main Claude relays this verbatim to the operator BEFORE invoking reviewer (sync gate per master CLAUDE.md §6 / pipeline.md).

- **`local_checks_attempted` is MANDATORY** with one row per gate command attempted: exact command, exit code, and one of `pass | fail | sandbox_block`. No silent skips. If a gate couldn't run, surface as `sandbox_block`, never as silent pass.

- **Refuse impossible work** — if any acceptance gate cannot be honestly verified, return Shape B with `sandbox_block` or `blocked: <reason>`. Never fabricate. The framework treats `sandbox_block` as red, not as a permissible skip.

- **Read DESIGN.md §lifecycle before writing code touching an external integration.** If the brief doesn't cite the relevant DESIGN section (or DESIGN.md doesn't cover the integration), surface to `open_questions` and stop. DESIGN.md must cover the lifecycle/sequence/source-of-truth BEFORE code lands; otherwise you'll write code that contradicts the design.

- **Mocks must enforce protocol contracts** (master CLAUDE.md §15 / testing-patterns.md). Any mock of an external client (SDK, HTTP, DB) must verify the call order it replaces — e.g. a mock SDK client should refuse `query()` calls that precede `connect()`. Mocks without contract enforcement are how tests-pass-on-broken-code bugs happen.

- **Doc maintenance in the SAME commit** (master CLAUDE.md §7). If your PR changes a documented fact (path, env var, schema field, CLI command), update the corresponding doc in this same commit. No "doc fix follow-up" exceptions. Main agent's pre-merge scope check will bounce the PR back if doc updates are missing.

- **Stay in your scope.** Files in the brief's file list are the contract; don't add files outside it without flagging via `open_questions`. Don't pull tasks from later phases.

- **Push only to `feature/*` / `fix/*` / `chore/*` / `docs/*` / `hotfix/*` / `feat/*` branches.** Never push to `dev` or `master`. The push guard in your procedure is load-bearing.

- **Don't shell-escape.** Never use `cd /abs/path && rm -rf`, `| sh`, `eval`, or `$(curl ... | sh)` patterns to bypass permissions. If you genuinely need a denied op, surface via `open_questions` for operator adjudication.
EOF
