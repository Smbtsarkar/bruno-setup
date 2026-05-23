# Main agent execution policy

Full version of the main-agent execution boundary. Summary lives in master CLAUDE.md §12; this is the reference.

---

## The boundary

The main agent (Bruno) **never executes project code**. Execution is the subagent's job.

"Project code" includes:

- Running the project's own tests (`pytest`, `npm test`, `cargo test`, `go test`, …).
- Running the project's own lint/format/typecheck (`ruff`, `mypy`, `tsc`, `eslint`, `prettier`, `gofmt`, `clippy`, …).
- Running the project's own build (`cargo build`, `npm run build`, `make`, …).
- Running the project's own entrypoints (`citadel serve`, `python -m foo`, `./bin/myapp`).
- Running the project's own dev servers, REPLs, scripts.
- Anything that **imports** the project's modules or **compiles** its source.

Why: every line of project-code output that lands in the main agent's context is context that can't be used for orchestration decisions. Subagents have their own context windows; let them absorb the output.

---

## What main agent CAN run

The main agent's `Bash` use is restricted to **orchestration plumbing**:

### Git / GitHub
- `git status`, `git log`, `git diff`, `git branch`, `git fetch`, `git checkout`, `git pull`
- `git add`, `git commit` (docs / config only — see "Docs exception" below)
- `git push` (feature branches only — `dev`/`master` push is `reviewer`'s job per master CLAUDE.md §6)
- `git tag`, `git push origin <tag>` (release-cut only, post senior-reviewer READY-TO-MERGE)
- `git merge` (with care — see master CLAUDE.md §3 destructive-ops list)
- `gh pr list`, `gh pr view`, `gh pr checks`, `gh run list`, `gh run view`, `gh run watch`
- `gh pr create` (only `reviewer` opens PRs normally; main agent opens only for docs-only PRs)
- `gh pr merge --squash --delete-branch` (after user approval)
- `gh api ...` (reading repo state — branches, files, releases)

### Filesystem inspection
- `ls`, `find`
- `cat`, `head`, `tail`, `wc`
- `grep`, `rg`
- `which`, `command -v`

These are read-only inspections of project state. Output goes into the main agent's context as needed.

### Slash-command `cd` exception
- `cd` is allowed only inside `/new-project` and `/switch-project` workflows, where the main agent moves between project roots.
- Outside those workflows, never use `cd`. Use absolute paths in tool args instead. Subagents that need a different CWD set it themselves.

---

## What main agent CAN write

### Markdown docs
The main agent **may write or edit Markdown documentation directly**, without delegating to `coder`. This includes:

- `README.md`, `CHANGELOG.md`
- `docs/REQUIREMENTS.md`, `docs/DESIGN.md`, `docs/PLAN.md`, `docs/LEARNINGS.md`, `docs/ARCHITECTURE.md`
- Per-project `CLAUDE.md`

Docs are not "production code" in the §12 sense. The exception exists because:
- Doc-only PRs don't benefit from coder's gate-running discipline (there's nothing to gate).
- Forcing every doc edit through coder produces overhead without value.
- Subagents (`docs`) still write docs when it makes sense (e.g. comprehensive README rewrite at PR time).

### Config and metadata files
- `.gitignore`, `.gitattributes`
- `.release-ignore` and similar strip-list files
- `pyproject.toml` version-bump-only edits (the rest of pyproject.toml is `coder`'s)
- `package.json` version-bump-only edits

The pattern: simple structural file edits that don't change behaviour are main-agent-allowed. Anything that touches code paths, dependencies, or test surface is `coder`'s.

### Plan files
- `~/.claude/plans/<plan-file>.md` (during plan-mode work)

---

## What main agent CANNOT write

- ❌ Production source code (`src/**/*.py`, `src/**/*.ts`, etc.).
- ❌ Test files (`tests/**/*.py`, etc.).
- ❌ Migration files (`alembic/versions/*.py`).
- ❌ Shell scripts that run in the project's deploy/CI path (`deploy/setup.sh`, `scripts/dev/*.sh`).
- ❌ CI workflow files (`.github/workflows/*.yml`) — unless the change is purely a job add/remove that the user explicitly asked for, in which case main agent may make minimal edits.
- ❌ Lockfiles (`uv.lock`, `package-lock.json`, `Cargo.lock`) — even single-line edits. Delegate to coder with `uv lock` / `npm install` / `cargo update`.

The lockfile rule has one practical loophole: if `coder` is sandbox-blocked from running `uv lock` and the change is a single line (e.g. self-reference version bump), main agent may hand-edit the single line — but flag in the commit body that reviewer must re-run `uv lock` to confirm zero drift.

---

## Subagent execution ownership

| Subagent | Owns running |
|----------|--------------|
| `coder` | Project lint, type, unit + integration tests (per phase); writing tests; building artifacts; running CI workflow generation |
| `reviewer` | Full quality gate (lint, type, all tests, audit); e2e exercise of built artifact; install-gate exercise; Bruno API collection runs |
| `senior-reviewer` | Re-runs every gate at verdict time; install-walkthrough on clean container |
| `debugger` | Re-runs failing commands in diagnose-only mode; fetches logs |
| `scaffolder` | Template-init commands (`uv sync`, `npm install`, `cargo init`, etc.); first commit |
| `docs` | Doesn't run project code (verifies docs match observable behaviour from running components, but doesn't execute them itself) |
| `Explore` (system) | Read-only — no execution at all |

---

## If you find yourself wanting to run project code

**Stop.** Ask:
- Is this a one-off diagnostic? → spawn `debugger` with the command + log paths.
- Is this verification of a fix? → spawn `reviewer` (per-phase quick) with the fix's brief.
- Is this re-running gates after a coder return? → that's `reviewer`'s job; spawn it.
- Is this checking a hunch about behaviour? → use `Read` to read the code, not `Bash` to run it.

The pattern of "I'll just quickly run X to check" is how main-agent context fills with project-code output that doesn't belong there. Discipline holds the line.

---

## What main agent does with the time saved

By offloading execution, main agent stays focused on:

- Routing decisions (which subagent next, which brief, which scope).
- Operator synchronization (sync gate after coder, escalation surfaces).
- Doc maintenance (the master/per-project CLAUDE.md, REQUIREMENTS, DESIGN, PLAN, LEARNINGS).
- Release coordination (senior-reviewer invocation, tag-push approval, release-watch).

That's the orchestration layer. Anything below that layer is subagent work.
