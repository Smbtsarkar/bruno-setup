# Bruno framework — `settings.json`

Claude Code `settings.json` files for the Bruno framework: the base ruleset that applies everywhere, plus stack fragments the scaffolder merges at `/new-project` time. Project-specific extensions live with the project, not here.

---

## Files

| File | Goes to | Purpose |
|------|---------|---------|
| `settings.json` | `~/.claude/settings.json` AND `~/.claude/templates/_settings/base.json` | Framework defaults: permissions, hooks config, thinking levels |
| `templates/_settings/python-cli.fragment.json` | `~/.claude/templates/_settings/python-cli.fragment.json` | Scaffolder merges this into a new Python-CLI project's `.claude/settings.json` |
| `templates/_settings/claude-skill.fragment.json` | `~/.claude/templates/_settings/claude-skill.fragment.json` | Same, for `claude-skill` stack |

---

## Install

Run `scripts/sync.sh` from the repo root. It rsyncs `framework/` into `~/.claude/` (including the templates and stack fragments) and installs the base settings.

Verify:
```bash
python3 -c "import json; json.load(open('$HOME/.claude/settings.json'))" && echo "OK"
```

---

## Merge semantics — base + project + stack fragment

When Claude Code resolves a session's effective settings, it composes from three layers (highest priority last):

1. **User-global** — `~/.claude/settings.json` (= the framework `settings.json` post-install).
2. **Project** — `<project>/.claude/settings.json` (= scaffolded merge of `base.json` + applicable `<stack>.fragment.json`, or post-scaffold operator edits).
3. **Project-local override** — `<project>/.claude/settings.local.json` (gitignored; per-developer secrets / preferences).

**The Bruno framework's contract: project layers EXTEND, never OVERRIDE.** `permissions.allow` / `ask` / `deny` are **union sets** — projects add entries, never replace or remove entries the base declares.

This means:
- A project's `permissions.allow` adds project-specific entries; the base allow list (git, gh, ls, etc.) still applies.
- `permissions.deny` in the base is the floor — no project can re-allow what the base denies. Forbidden patterns stay forbidden.
- `permissions.ask` similarly stacks; project additions raise additional approval prompts but don't suppress base ones.

If you find yourself wanting a project to override a base entry, that's a signal the base entry is wrong. Fix the base.

The scaffolder (`~/.claude/agents/scaffolder.md`) implements this union semantics for stack fragments at `/new-project` time. For operator-edited project settings, Claude Code's settings resolver handles the layering — but the operator should still follow the union convention.

---

## What's in the base `settings.json`

### Notification + thinking defaults
- `effortLevel: "high"` — Bruno (main session) uses high thinking depth by default.
- `alwaysThinkingEnabled: true` — extended thinking on for all subagent invocations.
- `showThinkingSummaries: true` — thinking blocks visible in output.
- Notifications: `inputNeededNotifEnabled`, `agentPushNotifEnabled` on; `skipAutoPermissionPrompt` on (auto-mode preserves prior session's prompts).

### Permissions
- `defaultMode: "auto"` — Bruno operates autonomously; deny patterns are the floor.
- `allow` (~50 entries) — routine git, gh, filesystem inspection, env reads.
- `ask` (~20 entries) — destructive git ops, PR merges, releases, sudo, network ops.
- `deny` (~40 entries) — catastrophic ops (`rm -rf`, `dd`), shell-escape vectors (`| sh`, `eval`, `$()`), framework self-modification (`~/.claude/**`), secret-file reads, branch hygiene (no push to dev/master).

**Defense-in-depth note:** see `hooks/README.md` for how `permissions.deny` glob matching plus `hooks/enforcement/compound-command-check.sh` together cover shell-escape patterns that single-layer glob matching would miss (e.g. `cd /tmp && rm -rf /`).

### Hooks
- `SessionStart` — `bruno.sh` injects session context (three-doc maintenance reminders, doc verification rule, sync-gate posture).
- `SubagentStart` per agent — each of `coder`, `reviewer`, `senior-reviewer`, `debugger`, `docs`, `scaffolder` gets a per-agent context injection on spawn.
- `PreToolUse Bash` chain — `compound-command-check.sh` (first), `project-root-bash.sh`, `relative-path-check.sh`, and `pre-commit-installed.sh` (conditional on git commit).
- `PostToolUse Edit|Write` — `doc-drift-reminder.sh` nudges on doc-tracked file edits.
- `PostToolUse Bash` — `destructive-op-log.sh` writes forensics for actual destructive ops.
- `UserPromptSubmit` — `debugger-auto-invoke.sh` detects pasted error output and suggests spawning debugger.
- `CwdChanged` — `cwd-escape-block.sh` blocks CWD escapes outside project root.
- `Stop` — `task-stale-on-stop.sh` warns about in-progress tasks at end of turn.

### Security posture
- `allowedHttpHookUrls: []` — no HTTP hooks; no outbound URLs from hook calls.
- `httpHookAllowedEnvVars: []` — no env-var leakage to HTTP hooks (defensive even with no HTTP hooks).
- `disableAllHooks: false` — hooks are mandatory; an operator who wants to disable a single hook should edit the base `settings.json` and document the reason.

---

## Per-project extensions

Project-specific permissions, hook references, and allowlist entries live in `<project>/.claude/settings.json`, **not** in this repo. The framework stays project-agnostic on purpose.

A typical project addition looks like:

```json
{
  "permissions": {
    "allow": [
      "Bash(<project> *)",
      "Bash(sudo systemctl * <project>.service)",
      "Read(/etc/<project>/**)",
      "Read(/var/lib/<project>/**)"
    ],
    "ask": [
      "Bash(git tag v*)",
      "Bash(git push origin v*)"
    ]
  }
}
```

Per union semantics, those entries stack on top of the base — they don't replace any framework defaults. The project repo is the source of truth for project-specific operational paths, service names, and tooling allows.

---

## Stack fragments

Each fragment is merged with the base by the scaffolder when a project of that stack is initialised via `/new-project`. Fragments **only add** stack-specific allow / deny entries — they never override base.

Current fragments:
- `python-cli` — allows `uv *`, `pytest`, `ruff`, `mypy`; denies `pip install*` (forces uv-managed installs).
- `claude-skill` — allows `npm test`, `npx tsc`; denies `npm install*` (forces deterministic installs).

Adding a new stack:
1. Create `~/.claude/templates/<stack>/` with the project template.
2. Create `~/.claude/templates/_settings/<stack>.fragment.json` mirroring the existing fragments.
3. Scaffolder auto-detects and merges on `/new-project <stack>`.

---

## See also

- `hooks/README.md` — hook architecture, script conventions, exit-code semantics, defense-in-depth layering.
- `CLAUDE.md` §1, §3, §6, §7 — the rules that the permissions and hooks enforce.
- `docs/execution-policy.md` — main-agent execution boundary, which the deny list helps enforce.
