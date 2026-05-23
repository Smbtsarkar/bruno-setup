---
description: Switch Bruno's active project to a different folder under ~/workspace-bruno/. Requires operator approval before the switch is applied.
---

The operator has requested a project switch to: **$ARGUMENTS**

Per master CLAUDE.md workspace section / workspace.md (Workspace root + project switching), follow this flow:

1. **Validate the target.**
   - Confirm `~/workspace-bruno/$ARGUMENTS/` exists. If not, surface the error and stop.
   - Confirm it is a git repo (contains `.git/`). If not, warn but allow the switch (some projects are non-git).
   - Read `~/workspace-bruno/$ARGUMENTS/CLAUDE.md` to confirm it exists and starts with the inheritance clause `> Inherits from ~/.claude/CLAUDE.md`. If missing, warn that the project may not be Bruno-managed.

2. **Confirm with the operator** before changing CWD. State explicitly:
   - Current project: (basename of current `$CLAUDE_PROJECT_DIR`)
   - Target project: `$ARGUMENTS`
   - Any warnings from step 1.
   - Ask: "Confirm switch? [y/n]"

3. **On confirmation:**
   - `cd ~/workspace-bruno/$ARGUMENTS` (this is the slash-command `cd` exception per `framework/docs/execution-policy.md`).
   - Re-read the new project's `CLAUDE.md` for project-specific rules.
   - Run any project-specific preflight that the new `CLAUDE.md` declares.
   - Report the new active project to the operator.

4. **On rejection / silence:**
   - Stay in the current project. Do not modify anything.

Do not switch without explicit confirmation. Do not skip the validation step even if the operator seems impatient — a typo'd project name can land Bruno in a non-Bruno-managed directory and cause unexpected behaviour.
