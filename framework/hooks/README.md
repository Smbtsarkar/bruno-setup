# Bruno framework — `hooks/`

Claude Code hook scripts referenced by `~/.claude/settings.json` (= `settings/base.json` post-install). All scripts read JSON from stdin and use exit codes / stdout / stderr per the Claude Code hook contract.

---

## Install

```bash
# Create destination dirs
mkdir -p ~/.claude/hooks/{system-prompt,enforcement,audit}

# Copy scripts (preserve subdirectory structure)
cp -r hooks/system-prompt/*.sh ~/.claude/hooks/system-prompt/
cp -r hooks/enforcement/*.sh ~/.claude/hooks/enforcement/
cp -r hooks/audit/*.sh ~/.claude/hooks/audit/

# Make executable
chmod +x ~/.claude/hooks/**/*.sh

# Verify
for f in ~/.claude/hooks/**/*.sh; do bash -n "$f" || echo "SYNTAX FAIL: $f"; done
ls -la ~/.claude/hooks/**/*.sh | grep -v '^-rwx' && echo "FAIL: non-executable hooks"
```

Hooks reference `$HOME/.claude/hooks/...` in `settings/base.json` — install to that path exactly.

---

## Dependencies

All hook scripts require:

- **bash** (≥4.0) — uses arrays and `[[ ]]`.
- **jq** — for parsing JSON from stdin. Install via `apt-get install jq` / `brew install jq`. Without jq, hooks degrade gracefully (skip with a stderr warning) rather than blocking.

Optional:

- **realpath** — used by `project-root-bash.sh` and `cwd-escape-block.sh` for symlink resolution. If absent, scripts use raw paths (slightly less robust against symlink-based escapes).
- **grep with `-P`** — Perl regex. Used by `compound-command-check.sh` and others. GNU grep has it; BSD grep doesn't (macOS uses BSD grep by default; install via `brew install grep` and use `ggrep`, or use `gsed` and explicit `-E`).

---

## Hook architecture

### Three categories

1. **`system-prompt/`** — `SessionStart` (for Bruno) and `SubagentStart` (per subagent). Each script `cat`s a fixed reminder block to stdout; Claude Code prepends it to the agent's session context. Exit 0 always; never blocks.

2. **`enforcement/`** — `PreToolUse` (for Bash and Edit|Write), `UserPromptSubmit`, `CwdChanged`. These scripts make allow/block decisions:
   - Exit 0 = allow (action proceeds).
   - Exit 2 + stderr = block (action does not proceed; stderr shown to the agent as feedback).
   - Exit 0 + stdout = allow but inject context (stdout becomes part of the agent's next turn).
   - Other exit codes = log warning but proceed.

3. **`audit/`** — `PostToolUse` (for Bash) and `Stop`. Read-only forensics or end-of-turn checks. Exit 0; never blocks. Side effects: append to log files or inject reminders.

### Exit code semantics (per Claude Code hook contract)

| Exit | Meaning | Side effects |
|------|---------|--------------|
| 0 + empty stdout | Allow; no context injection | None |
| 0 + non-empty stdout | Allow; **stdout becomes injected context** for the next turn | Context grows |
| 2 + stderr | **Block** the action | Stderr fed back to agent as feedback |
| Other | Allow but log warning | Operator may see warning |

For structured decisions, scripts can also emit JSON to stdout (exit 0):
```json
{"decision": "block", "reason": "...", "additionalContext": "..."}
```
But we use the simpler exit-code path for clarity in this framework.

### Hook event JSON shape (input to hook script via stdin)

Common fields across events:
- `session_id` — the Claude Code session ID
- `cwd` — current working directory (for events where applicable)
- `tool_name` — for `PreToolUse` / `PostToolUse` (e.g. `"Bash"`, `"Edit"`, `"Write"`)
- `tool_input` — for tool events; structure depends on the tool (e.g. `Bash` has `{ command }`; `Edit` has `{ file_path, old_string, new_string }`)
- `tool_response` — for `PostToolUse` (e.g. `{ exit_code, output }`)
- `prompt` — for `UserPromptSubmit`

Hooks read JSON via `jq` from stdin. Reference: https://code.claude.com/docs/en/hooks.md.

---

## Defense-in-depth layering (the answer to "how do we prevent shell-escape?")

The framework uses SIX layers to block patterns like `cd /tmp && rm -rf /` or `cat | sh`:

| # | Layer | Where | Catches |
|---|-------|-------|---------|
| 1 | Anywhere-match permission globs | `settings/base.json` `permissions.deny` | `Bash(*rm -rf *)`, `Bash(*\| sh*)`, `Bash(*curl * \| bash*)` — matches substring anywhere in command |
| 2 | `compound-command-check.sh` | This dir | Splits on `&&`/`\|\|`/`;`/`\|`/`&`/backticks/`$()`; regex-checks each chunk; catches what glob misses |
| 3 | `project-root-bash.sh` | This dir | `\bcd\s+/[^\s]+` ANYWHERE in command; post-realpath check against safe-path list |
| 4 | `defaultMode: "auto"` (NOT bypassPermissions) | `settings/base.json` | Claude Code's permission engine runs deny patterns before tool execution. `bypassPermissions` would skip scoped denies — we don't use it. |
| 5 | `system-prompt/*` hooks | This dir | Each subagent gets explicit reminder: "never use shell-escape; escalate via open_questions instead" |
| 6 | `audit/destructive-op-log.sh` | This dir | `PostToolUse` Bash logs forensics for anything that did run |

**Honest limitation:** layers 1-3 are heuristic. Bash grammar is too rich for regex to parse perfectly — adversarial commands with heredocs, parameter expansion (`${PATH##*/}`), or extensive escaping can in principle slip through. The combination of layers narrows the attack surface to where subagents acting in good faith won't trigger denies, while bad-faith bypass attempts hit at least one layer.

**Posture:** agents are trusted to follow contracts; permissions + hooks are the safety net when they don't. No single layer is the wall.

---

## Per-hook reference

### system-prompt/
| Script | Hook event | Matcher | Purpose |
|--------|-----------|---------|---------|
| `bruno.sh` | `SessionStart` | — | Injects framework rules into Bruno's first turn |
| `coder.sh` | `SubagentStart` | `coder` | Reminds coder of return-contract fields, sandbox-block honesty, refuse-impossible, DESIGN.md reading |
| `reviewer.sh` | `SubagentStart` | `reviewer` | Reminds reviewer of env-pinning, adjacent-surface scan, doc-drift check, sandbox-block as Shape B |
| `senior-reviewer.sh` | `SubagentStart` | `senior-reviewer` | Reminds senior-reviewer of checklist-first, doc-drift = BLOCKER, install-walkthrough, non-blocking-needs-override |
| `debugger.sh` | `SubagentStart` | `debugger` | Reminds debugger of fetch-logs-yourself, DESIGN.md lifecycle reference, `DESIGN.md update needed?` field |
| `docs.sh` | `SubagentStart` | `docs` | Reminds docs of `drift_found` mandatory, no marketing fluff, no features-the-code-doesn't-have |
| `scaffolder.sh` | `SubagentStart` | `scaffolder` | Reminds scaffolder of DESIGN.md skeleton requirement, system Explore (not custom), inheritance clause |

### enforcement/
| Script | Hook event | Matcher | Purpose |
|--------|-----------|---------|---------|
| `compound-command-check.sh` | `PreToolUse` | `Bash` | Defense-in-depth shell-escape detection across compound commands; runs FIRST |
| `project-root-bash.sh` | `PreToolUse` | `Bash` | Blocks `cd /<abs>` outside project root |
| `relative-path-check.sh` | `PreToolUse` | `Bash` | Warns (doesn't block) on absolute paths in args |
| `pre-commit-installed.sh` | `PreToolUse` | `Bash`, `if: Bash(git commit *)` | Blocks git commit if pre-commit hook not installed but config exists |
| `debugger-auto-invoke.sh` | `UserPromptSubmit` | — | Detects pasted error output; injects "spawn debugger" reminder |
| `doc-drift-reminder.sh` | `PostToolUse` | `Edit\|Write` | Reminds to update REQUIREMENTS/DESIGN/README when doc-tracked file is edited |
| `cwd-escape-block.sh` | `CwdChanged` | — | Blocks CWD changes outside project root |

### audit/
| Script | Hook event | Matcher | Purpose |
|--------|-----------|---------|---------|
| `destructive-op-log.sh` | `PostToolUse` | `Bash` | Appends one line to `~/.claude/audit/destructive-ops.log` for any destructive op that ran |
| `task-stale-on-stop.sh` | `Stop` | — | At end of turn, reminds about any in_progress tasks |

---

## Customising per-project

Project-specific hooks go in `<project>/.claude/hooks/`. The project's `.claude/settings.json` references them. Per the framework's union semantics, project hooks **add** to the base set — they don't replace it.

For citadel specifically: no project-level hooks today. Everything the framework enforces is in `~/.claude/hooks/`. If citadel needs a citadel-specific hook (e.g. "block any change to `deploy/citadel.service` that doesn't update DESIGN.md §systemd"), add it under `citadel/.claude/hooks/` and reference from `citadel/.claude/settings.json` `hooks` block.

---

## Debugging hooks

If a hook misbehaves:

1. Run it manually with sample JSON:
   ```bash
   echo '{"tool_input":{"command":"cd /tmp && rm -rf /"}}' | bash ~/.claude/hooks/enforcement/compound-command-check.sh
   echo "exit: $?"
   ```
2. Tail the Claude Code log for hook output. (Path depends on Claude Code version; check via `claude --help`.)
3. Temporarily set `disableAllHooks: true` in `settings.json` to bypass (then re-enable; debug only).

Never edit hooks in `~/.claude/hooks/` directly — edit in `docs/proposed-framework/hooks/` (the staging source) and re-install.

---

## Resolves broken contracts

- The framework's `senior-reviewer` previously had a "look for shell-escape patterns" responsibility but no enforcement layer. With these hooks, blocks happen at PreToolUse — senior-reviewer becomes a backstop, not the primary gate.
- The framework's `coder` previously had "do not fabricate gate passes" as a behavioural rule. With `system-prompt/coder.sh` injection, the rule is reinforced at session start.
- The "operator-reported error → debugger" rule in master CLAUDE.md §8 had no enforcement. `debugger-auto-invoke.sh` makes it structural.

---

## See also

- `../settings/README.md` — settings.json layer (permissions, model defaults, hook config)
- `../CLAUDE.md` §4, §8, §17, §20, §21 — the framework rules these hooks enforce
- `../docs/execution-policy.md` — main-agent execution boundary
- Claude Code hooks reference: https://code.claude.com/docs/en/hooks.md
