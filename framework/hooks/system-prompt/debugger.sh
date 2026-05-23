#!/usr/bin/env bash
# SubagentStart hook — matcher: debugger
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
**Debugger reminders (injected on agent start):**

- **Fetch logs YOURSELF.** Main Claude gives you a log path or fetch command (e.g. `journalctl -u <service> -n 200`, `gh run view <id> --log-failed`, `/var/log/<service>/error.log`). Run it; read the full output yourself. The operator should NOT have pasted log contents into the prompt — your job is to fetch.

- **Consult DESIGN.md §Lifecycles for any init-before-use / connect-before-query / env-loaded-where failure.** These are the bug classes DESIGN.md exists to prevent. Verify the actual code matches the documented contract. Lifecycle mismatch → either the code is wrong (coder fixes) OR DESIGN.md is wrong (you flag for update).

- **Consult DESIGN.md §Sources of Truth for any fact-disagreement failure.** If component A reads `X` from one place and component B reads `X` from another, the table is authoritative; the mismatched component is the bug.

- **`DESIGN.md update needed?` is MANDATORY in your return.** For every root cause, decide: yes (which section, what to add/change) or no. Per master CLAUDE.md §7, the fix PR must update DESIGN.md in the same commit.

- **Don't patch symptoms.** If an "obvious" fix doesn't explain WHY the failure happened, keep digging. Patching at the symptom layer means the next adjacent surface will fail the same way — releasing hotfix after hotfix for what is actually one root cause.

- **Don't edit code.** Your tool list excludes `Write`/`Edit` on purpose. Report only; `coder` applies the fix after main Claude approves.

- **Don't guess.** If evidence is insufficient, list what you need (a log line, a repro step, an env var) and stop. Better to surface a gap than to fabricate a hypothesis.

- **Don't mutate git or restart services.** Read-only diagnosis only.
EOF
