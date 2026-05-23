# Workspace root and project switching

**The Bruno workspace root is `~/workspace-bruno/`** (override via env var `CLAUDE_WORKSPACE_ROOT`). Every project lives directly under it — `~/workspace-bruno/citadel/`, `~/workspace-bruno/garuda/`, etc. Bruno's blast radius for writes is confined to this folder; reads are broader (system inspection still works) with audit logging on cross-workspace reads.

---

## Capability matrix

| Operation | Inside `~/workspace-bruno/` | Outside (canonical safe paths) | Outside (other) |
|-----------|------------------------------|-------------------------------|-----------------|
| `Read`, `Glob`, `Grep` | Allowed | Allowed (`/etc/citadel/`, `/var/lib/citadel/`, `~/.claude/`, `/etc/os-release`, etc.) | Allowed; logged to `~/.claude/audit/cross-workspace-reads.log` |
| `Write`, `Edit` | Allowed | Denied — protected by deny patterns + `workspace-write-block.sh` hook | **Denied** (hard) |
| `Bash` execution | Allowed | Allowed via `permissions.allow` patterns | Allowed via `permissions.allow` patterns; `cd` outside workspace blocked by `cwd-escape-block.sh` |

Hooks (`framework/hooks/`) run as Claude Code infrastructure, not as Bruno tool calls — they're not subject to these restrictions and continue to function (OS detection, log fetching by debugger, framework-file reads).

---

## Project switching

Bruno cannot switch its working project autonomously. Two operator-driven flows:

1. **`/switch-project <name>`** — Claude Code-native slash command. Lives at `~/.claude/commands/switch-project.md`. Use in the Claude Code CLI.
2. **`!switch-project <name>`** — Text-pattern form. Detected by `UserPromptSubmit` hook (`switch-project-detect.sh`) so it works in any text interface — Claude Code CLI, Discord channels routed through a harness like Citadel, etc.

Both forms surface the same Bruno-handled flow:

1. Bruno acknowledges the requested switch.
2. Bruno checks that `~/workspace-bruno/<name>/` exists and is a git repo (or warns if not).
3. Bruno asks the operator to confirm: "Switch from `<current>` to `<name>`? [y/n]".
4. On confirmation, Bruno updates `$CLAUDE_PROJECT_DIR` (via `cd` — the one place outside `/new-project` where `cd` is permitted, per `execution-policy.md` §"slash-command cd exception").
5. Bruno re-runs preflight checks for the new project's `CLAUDE.md` / inheritance clause.

Mid-session approval is per-switch, not session-wide. If you switch from `citadel` to `garuda` and back, both transitions require approval.

---

## Migration notes

If you're moving from `~/Projects/` to `~/workspace-bruno/`:

- Move existing projects: `mv ~/Projects/<name> ~/workspace-bruno/<name>` (or symlink during transition: `ln -s ~/workspace-bruno/<name> ~/Projects/<name>`).
- Override the default if needed: `export CLAUDE_WORKSPACE_ROOT=/path/to/some/other/workspace` before starting Claude Code.
- Update IDE bookmarks, shell aliases, and any sister scripts that referenced `~/Projects/`.
- Backup discipline: the workspace folder is now a single point of failure. Set up automated backups of `~/workspace-bruno/` to external storage.

---

## Anti-patterns

- ❌ Bruno opening files outside the workspace to "just take a quick look" without operator awareness. The audit log catches this; the operator can review.
- ❌ Writing config or data files outside the workspace. If a project needs to write to `/etc/<project>/`, that's a deployment step the project owns — Bruno orchestrates it via Bash (which is permitted), not via direct file writes.
- ❌ `cd ~/some-other-directory` mid-session. Use `/switch-project` if it's a workspace project; otherwise, stay put.
- ❌ Using the absolute path `~/Projects/...` in any new file or doc. The path is `~/workspace-bruno/...`.
