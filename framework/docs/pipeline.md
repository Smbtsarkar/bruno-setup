# Bruno orchestration pipeline

Bruno's main agent orchestrates the engineering pipeline. Specialized subagents handle distinct phases; main agent **auto-invokes** them based on context — the operator does not need to ask.

Requirements gathering and planning are **main-agent work** — main agent runs the interview and writes the plan following `requirements.md` and `plan.md`. There is no `interviewer` or `planner` subagent.

---

## Subagent roster

Full definitions live in `~/.claude/agents/`. Quick reference:

| Agent             | Role                                                                                                                                                                                                                                                                                          |
| ----------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `Explore` (system) | Read-only codebase exploration. **Use the Claude Code system `Explore` agent** (capital E). Do not use a custom `explorer` — that pattern has been retired.                                                                                                                                  |
| `scaffolder`      | Copies templates from `~/.claude/templates/<stack>/` and customizes                                                                                                                                                                                                                           |
| `coder`           | Implements PLAN.md phases, writes unit + integration tests, Bruno collections, and the CI workflow. Commits per phase. Output contract includes `summary_for_operator` (see Sync gate below)                                                                                                  |
| `reviewer`        | Code review (style, security, tests, perf, architecture/design) — per-phase quick review and pre-PR comprehensive review. Comprehensive mode also (a) drives the built artifact end-to-end and (b) scans for adjacent surfaces with the same root cause as the brief's reported bug          |
| `senior-reviewer` | Final pre-release review — verifies code matches PLAN.md / REQUIREMENTS.md / DESIGN.md, re-runs every quality gate, sweeps for loose ends, runs install-walkthrough. Read-only. Returns a single verdict (READY-TO-MERGE / NEEDS-WORK / BLOCKED). Auto-invoked before any `dev` → `master` PR |
| `debugger`        | Diagnose-only; reports root cause + suggested fix. **Auto-invoked on any operator-reported error output** — see Debugger auto-invoke below                                                                                                                                                    |
| `docs`            | Owns README, CHANGELOG, API docs, architecture/usage guides, inline comments. `drift_found` is a mandatory return field — flags any doc-vs-code mismatch for coder                                                                                                                            |

---

## Standard pipeline for `/new-project`

```
Requirements interview (main, per requirements.md playbook)
  → DESIGN.md authoring (main, per design.md playbook — REQUIRED if external integrations declared)
  → Plan (main, per plan.md playbook)
  → Scaffolder
  → (Coder → main-agent sync gate → Reviewer (per-phase) loop)
  → Reviewer (comprehensive, incl. e2e exercise + adjacent-surface scan)
  → Docs
  → PR
  → user approval
  → merge
```

The first three steps (interview, design, plan) are main-agent work, not a subagent's. Use the playbooks as scripts.

---

## Pipeline for ongoing work in an existing project

Main agent is **adaptive**.

### Pre-flight checks

Run these before any pipeline step. If any fail, stop and report; do not proceed.

1. **Branch model.** Confirm a `dev` branch exists. If it does not, and this is not the `claude-setup` exception, stop: tell the operator the repo is missing a `dev` branch and ask how to proceed — do not create it automatically.
2. **Current branch.** Confirm the working branch is not `master` or `dev` directly. If it is, stop and tell the operator to create a feature branch before continuing.
3. **Per-project `CLAUDE.md`.** Confirm a `CLAUDE.md` exists at the project root and references the master rules. If it's missing, create a minimal one from `~/.claude/templates/project-CLAUDE.md` before proceeding.
4. **DESIGN.md presence.** If the project has external integrations and DESIGN.md is missing, stop and surface to the operator. Do not proceed without DESIGN.md.

### Adaptive flow

Once pre-flight passes:

1. Check whether `docs/REQUIREMENTS.md`, `docs/DESIGN.md`, `docs/PLAN.md`, and `docs/ARCHITECTURE.md` exist and look current.
2. If any are missing or look stale → invoke `Explore` to map the codebase and report findings inline.
3. If requirements are unclear after exploration → run a focused requirements interview per `requirements.md`.
4. If no plan exists (or the existing one doesn't cover the new ask) → write or update `docs/PLAN.md` per `plan.md` and get the operator's approval before proceeding.
5. Then proceed with `coder` → **sync gate to operator** → `reviewer` (per-phase quick) → repeat for next phase → `reviewer` (comprehensive, incl. e2e exercise + adjacent-surface scan) → `docs` (only if PR-bound) → `gh pr create --base dev` → approval → `gh pr merge --squash --delete-branch`.
6. `debugger` is auto-invoked any time main agent observes a stack trace or unexpected non-zero exit during a run/test, OR whenever the operator pastes/references error output (see Debugger auto-invoke below).

---

## Sync gate after coder

After a coder returns, **before** invoking reviewer:

1. Quote the coder's `summary_for_operator` field verbatim to the operator (2-3 lines).
2. If the summary surfaces a scope question, an open question, or anything that deviates from the brief, pause for operator input.
3. If the operator is silent or says "go" / "proceed", invoke reviewer.

This step exists because reviewer reviews code, not "is this what the operator wanted". The sync gate catches off-spec work before reviewer burns time running gates on it.

---

## Debugger auto-invoke

Whenever the operator surfaces error output — a stack trace, a failing test summary, a `journalctl -u <service>` excerpt, a log fragment, an HTTP 5xx response body, any "X is broken, here's what I saw" message — **default to spawning `debugger` with the log paths/context**, NOT reading and diagnosing inline.

Inline diagnosis is permitted only when:

- (a) The failure is a one-line obvious mistake derivable from current conversation context (e.g. "you renamed `foo` to `bar` two messages ago"); OR
- (b) `debugger` has already run on this specific failure and returned, and main agent is following up on its findings.

Why: the previous pattern of main agent reading 30 lines of pasted journalctl in the foreground burned main-agent context and produced symptom-level fixes. Debugger is dedicated to root-cause analysis with its own context window. Operators should be able to paste a log *path* (or a 2-line summary) rather than the full log text.

When invoking debugger:

- Pass the log path or log-fetching command (e.g. `journalctl -u citadel.service -n 200 --no-pager`).
- Pass the failure summary in one line.
- Optionally pass a reproduction step.
- Debugger fetches and reads the logs itself.

---

## Senior-reviewer before any operator-test ask

`senior-reviewer` is auto-invoked **not only at release-cut time, but before any feature/PR is presented to the operator for manual verification.** The operator's test is the LAST step in the pipeline; senior-reviewer's validation is the second-to-last.

Triggers for auto-invocation:

1. Release cut (`dev` → `master`, or tag push) — the canonical trigger.
2. Feature complete: a PR that the operator will be asked to exercise / approve / try out before merging.
3. Major-milestone phase boundary: end of Phase 3 / 5 / 7 (or equivalent for the project's plan).

**Senior-reviewer's first deliverable is a checklist.** Before running gates or reading code, senior-reviewer produces an explicit checklist of what it will validate, grounded in:

- `docs/REQUIREMENTS.md` — capability coverage, operator-flow coverage
- `docs/DESIGN.md` — lifecycle, sequence, source-of-truth, error-contract coverage
- `docs/PLAN.md` — PR completion, acceptance-criteria coverage
- per-project `CLAUDE.md` — stack-specific commands and rules

Main agent surfaces the checklist + verdict to the operator. The operator sees WHAT was verified before WHAT the verdict was.

---

## Release-cut pipeline (`dev` → `master`)

`senior-reviewer` is the **release gate**. When the operator signals intent to cut a release (e.g. "release", "merge to master", "tag a version") or when main agent is about to ask for approval to open a `dev` → `master` PR, **auto-invoke `senior-reviewer` first**. Surface its verdict verbatim, then ask for approval.

The release gate also runs the project's **install-walkthrough** as part of the comprehensive check — not just unit tests, not just CI green, but a real install simulation on a clean container/VM. Generalises the per-project `scripts/dev/install-gate.sh` pattern.

Senior-reviewer returns one of three verdicts:

- `READY-TO-MERGE` → surface the report, then ask the operator whether to open the release PR.
- `NEEDS-WORK` / `BLOCKED` → surface the punch list, ask whether to loop with `coder` to address it. Do not open the release PR. After fixes land, re-invoke `senior-reviewer` and repeat until `READY-TO-MERGE`.

Never open the release PR without a fresh `READY-TO-MERGE` verdict, unless the operator explicitly overrides. **"Non-blocking" findings still gate the release by default** — they require explicit operator override to ship as-is.

---

## Subagent briefs

Subagents receive a self-contained brief — they do not read PLAN.md end-to-end. A brief is **40 lines or fewer by default**. If a brief exceeds 40 lines, the missing context belongs in DESIGN.md, not the brief. Cite canonical doc sections rather than restating them.

## Hand-offs

When an agent finishes, it returns a brief structured summary to main agent:

- What it did (files touched, doc written)
- What it found / decided
- What the next agent (if any) needs

Main agent is responsible for orchestrating; agents do not invoke each other directly.
