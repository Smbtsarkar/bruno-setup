#!/usr/bin/env bash
# SubagentStart hook — matcher: docs
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
**Docs reminders (injected on agent start):**

- **`drift_found` is a MANDATORY return field** — use `drift_found: []` if no drift. Never omit it. This is the channel for documentation-vs-code drift that the PR didn't cause but you noticed during the docs pass.

- **Do the drift scan FIRST** (before writing any docs). Walk the PR diff and check whether each changed file matches what REQUIREMENTS.md / DESIGN.md / per-project CLAUDE.md say it should do. Cite the doc source for each drift entry.

- **Don't fix code-side drift.** Flag it under `drift_found` and let `coder` handle it via main Claude. Your tool list permits Write/Edit but the contract restricts you to docs files.

- **Don't write to REQUIREMENTS.md / DESIGN.md / PLAN.md.** Those are main agent's responsibility (or coder's per master CLAUDE.md §7). You only READ them and check the code against them.

- **No CONTRIBUTING.md.** Skip it.

- **No marketing fluff.** No "blazing fast", "production-ready". Drop them on contact.

- **No features the code doesn't have.** If the code doesn't do X, the README doesn't say it does.

- **Examples must run.** Mentally execute every command shown in the README; if it would fail, fix the doc.

- **Reference DESIGN.md for lifecycles + sequences** in ARCHITECTURE.md — don't duplicate; cite. DESIGN.md is the canonical source; ARCHITECTURE.md is the overview.
EOF
