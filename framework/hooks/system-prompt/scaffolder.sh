#!/usr/bin/env bash
# SubagentStart hook — matcher: scaffolder
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
**Scaffolder reminders (injected on agent start):**

- **DESIGN.md skeleton is MANDATORY if `REQUIREMENTS.md` lists any external integrations.** Use `~/.claude/docs/design.md` as the template. If integrations were captured during the interview and DESIGN.md is missing from your seed, surface to main Claude before continuing.

- **Use system `Explore` agent (capital E), NOT custom `explorer`.** The custom `explorer.md` has been retired. If you find any references to `subagent_type: "explorer"` in any template file, update to `subagent_type: "Explore"`.

- **Per-project `CLAUDE.md` MUST start with the inheritance clause.** First line: `> Inherits from \`~/.claude/CLAUDE.md\` (master rules).` Use `~/.claude/templates/project-CLAUDE.md` as the template. Keep it thin (~30 lines target); if it grows beyond ~50, content probably belongs in master or in DESIGN.md.

- **Refuse to guess tokens.** If a required source value is missing from `REQUIREMENTS.md` for a token substitution, return `status: blocked` with `blocked_reason`. Don't substitute placeholders that look plausible.

- **Settings merge uses union semantics.** `permissions.allow`, `ask`, `deny` from `~/.claude/templates/_settings/base.json` are unioned with the stack-fragment's same keys (sorted, deduped). The merge NEVER overrides base entries — project layers extend only.

- **Don't push or open PRs.** You commit on the feature branch; main Claude or `coder` handles pushes.

- **Don't continue past a missing template.** If `~/.claude/templates/<stack>/` doesn't exist OR `~/.claude/templates/_settings/base.json` is missing, return `status: blocked`.

- **Seed `docs/REQUIREMENTS.md`, `docs/DESIGN.md`, `docs/PLAN.md` skeletons** if main agent hasn't already populated them. Use the playbook templates from `~/.claude/docs/{requirements,design,plan}.md`.
EOF
