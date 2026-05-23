# bruno-setup

Canonical source for the Bruno agent framework's `~/.claude/` files.

This repo holds the master `CLAUDE.md`, six subagent definitions, playbooks, settings.json, and hooks that together implement the Chief Engineer persona Bruno uses to operate any project. The `framework/` subdirectory mirrors `~/.claude/` exactly; a sync script rsyncs it into place.

See `framework/CLAUDE.md` for the full rule set; `framework/docs/` for the requirements/design/plan playbooks; `framework/hooks/README.md` for the enforcement-layer architecture.

---

## Install

```bash
# Clone (once)
git clone https://github.com/Smbtsarkar/bruno-setup.git ~/workspace-bruno/bruno-setup

# Sync into ~/.claude/
cd ~/workspace-bruno/bruno-setup
bash scripts/sync.sh
```

The sync:
- Copies `framework/CLAUDE.md` → `~/.claude/CLAUDE.md`
- Copies `framework/settings.json` → `~/.claude/settings.json` (and `~/.claude/templates/_settings/base.json` for scaffolder)
- Copies `framework/agents/*.md` → `~/.claude/agents/`
- Copies `framework/docs/*.md` → `~/.claude/docs/`
- Copies `framework/templates/*` → `~/.claude/templates/` (including `_settings/` stack fragments)
- Copies `framework/hooks/**/*` → `~/.claude/hooks/`
- `chmod +x` all hook scripts

Existing `~/.claude/` files are backed up to `~/.claude/<file>.bak.<timestamp>` before being replaced.

Restart any open Claude Code sessions to pick up the new settings + hooks.

---

## Update

```bash
cd ~/workspace-bruno/bruno-setup
git pull origin master
bash scripts/sync.sh
```

Same sync runs; same backup behaviour.

---

## Dependencies

- **bash** (4.0+) — required for hook scripts.
- **rsync** — required for `scripts/sync.sh`. Pre-installed on macOS and most Linux distros. On Windows, comes with Git for Windows (git-bash).
- **jq** — required by enforcement hooks to parse JSON from stdin. Install via `brew install jq` / `apt-get install jq` / `winget install jq`.
- **shellcheck** (optional, for development) — useful if a project pre-commit lints the hook scripts.

---

## What's in `framework/`

| Subdir | Purpose | See |
|--------|---------|-----|
| `framework/CLAUDE.md` | Master Bruno persona + rule sections | (the file) |
| `framework/agents/` | 6 subagent definitions with frontmatter (model, effort, tools) | (the files) |
| `framework/docs/` | Interview, planning, and DESIGN.md playbooks; execution policy; pipeline; subagent contracts; escalation; testing patterns; install walkthrough; deployment gate; workspace; pr-template; who-does-what; canonical-references | `framework/docs/` |
| `framework/templates/` | `project-CLAUDE.md` template for new projects + `_settings/` for scaffolder merge | `framework/templates/project-CLAUDE.md` |
| `framework/settings.json` | Permissions (Bash + PowerShell mirrors), hooks, thinking levels | `framework/settings-README.md` |
| `framework/hooks/system-prompt/` | SessionStart + per-agent SubagentStart context injection | `framework/hooks/README.md` |
| `framework/hooks/enforcement/` | PreToolUse/UserPromptSubmit/CwdChanged blocks | `framework/hooks/README.md` |
| `framework/hooks/audit/` | PostToolUse/Stop forensics | `framework/hooks/README.md` |

---

## Workspace conventions

Bruno operates under a single workspace root: **`~/workspace-bruno/`** (override via env var `CLAUDE_WORKSPACE_ROOT`). All projects live directly under it — `~/workspace-bruno/<project>/`.

The framework restricts Bruno's **Write/Edit** operations to this workspace (load-bearing blast-radius constraint per `framework/CLAUDE.md` workspace section / `framework/docs/workspace.md`). **Read/Glob/Grep** remain broad (system inspection still works) with audit logging on cross-workspace reads. **Bash execution** stays permitted via the existing allow patterns; `cd` between projects is gated by the `/switch-project` flow.

### Project switching

Bruno cannot switch its active project autonomously. Two equivalent operator-driven flows:

- **`/switch-project <name>`** — Claude Code CLI slash command. See `framework/commands/switch-project.md`.
- **`!switch-project <name>`** — Text-pattern form for non-CLI interfaces (any channel routed through a harness that forwards prompts). Detected by `framework/hooks/enforcement/switch-project-detect.sh`.

Both surface the same Bruno-handled flow: validate the target, ask the operator to confirm, then `cd` on approval.

### Setting up the workspace

```bash
mkdir -p ~/workspace-bruno
# Then either clone projects directly into ~/workspace-bruno/<name>
# or override the default root if you want a different location:
export CLAUDE_WORKSPACE_ROOT=/path/to/your/root
```

---

## Shell discipline (cross-platform)

The framework is designed to work on Linux, macOS, and Windows. The shell-discipline rule (`framework/CLAUDE.md` §16) says:

- **On Windows:** agents use the PowerShell tool exclusively; paths in `C:\Users\<user>\...` form.
- **On Linux / macOS:** agents use the Bash tool exclusively; paths in `/home/<user>/...` (or `/Users/<user>/...`) form.

`framework/settings.json` has permission patterns for both `Bash(*)` and `PowerShell(*)` so the right tool is allowed/denied on each OS. The `bruno.sh` SessionStart hook detects the OS at session start and injects the matching guidance into Bruno's context; each subagent's SubagentStart hook does the same.

---

## Single-branch model

This repo follows the single-branch exception (per `framework/CLAUDE.md` §5) — master only, direct commits, no feature branches, no PRs, no release ceremony. Reason: framework infra, single operator, no public consumers requiring PR-style review history.

To make a change:
1. Edit under `framework/`.
2. `git add . && git commit -m "<conventional>: <desc>"` on master.
3. `git push origin master`.
4. `bash scripts/sync.sh`.
5. Restart Claude Code.
