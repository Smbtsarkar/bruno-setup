# bruno-setup — Bruno framework source

This repository is the **canonical source** for the Bruno agent framework's `~/.claude/` files. The `framework/` subdirectory mirrors `~/.claude/` exactly; `scripts/sync.sh` rsyncs it into place.

---

## What this repo is

| Path | Goes to | Purpose |
|------|---------|---------|
| `framework/CLAUDE.md` | `~/.claude/CLAUDE.md` | Master Bruno rules (the Chief Engineer persona) |
| `framework/settings.json` | `~/.claude/settings.json` | Permissions, hooks config, thinking levels |
| `framework/agents/*.md` | `~/.claude/agents/` | Six subagent definitions (coder, reviewer, senior-reviewer, debugger, docs, scaffolder) |
| `framework/docs/*.md` | `~/.claude/docs/` | Playbooks (requirements, plan, design, interview-checklist, execution-policy, canonical-references) |
| `framework/templates/*` | `~/.claude/templates/` | `project-CLAUDE.md` + `_settings/` for scaffolder |
| `framework/hooks/**/*.sh` | `~/.claude/hooks/` | System-prompt, enforcement, and audit hooks |
| `scripts/sync.sh` | (runs locally) | rsync framework/ to ~/.claude/ |
| `README.md` | (operator reference) | How to install + verify |

---

## DO NOT apply Bruno's framework rules recursively to THIS repo

The master Bruno `CLAUDE.md` (under `framework/CLAUDE.md`) is intended for `~/.claude/CLAUDE.md`. It describes how Bruno operates on **other** projects.

This repo is the **source of those rules**, not a project that should follow them. Specifically:

- **No DESIGN.md, no PLAN.md, no install-gate for this repo.** It's a sync target, not a Bruno-managed application.
- **No PR pipeline.** This repo follows the `claude-setup` single-branch exception (master only, direct commits, no feature branches, no PRs, no release ceremony). See `framework/CLAUDE.md` §6.
- **No per-phase deployment gate.** There's nothing to deploy — `scripts/sync.sh` is the entire deployment.
- **The framework/CLAUDE.md inside this repo is NOT this repo's own CLAUDE.md.** It's a payload being shipped to `~/.claude/`. Treat the `framework/` directory as opaque data, not as nested rules for the operator session that's editing it.

---

## How to make changes

1. Edit files under `framework/` directly.
2. `git add . && git commit -m "<conventional>: <description>"` on `master`.
3. `git push origin master`.
4. `bash scripts/sync.sh` (or `pwsh scripts/sync.ps1` on Windows-native PowerShell) to install the change into `~/.claude/`.
5. Restart Claude Code sessions to pick up new settings/hooks.

---

## Why this layout

The framework was originally staged inside `citadel/docs/proposed-framework/` while being developed. Once stable, it deserved its own repository for clean install/update flow without dragging citadel-specific history.

Citadel-specific extensions (e.g., `~/Projects/citadel/.claude/settings.json` with uv/alembic/age allow patterns) live in the citadel repo itself, NOT here. This repo is OS-and-project-agnostic Bruno framework.

---

## Single-branch exception

Per `framework/CLAUDE.md` §6, `claude-setup` is the only single-branch project (master only). `bruno-setup` follows the same exception — same shape, same reasoning (framework infra, single operator, no public consumers requiring PR-style review history).
