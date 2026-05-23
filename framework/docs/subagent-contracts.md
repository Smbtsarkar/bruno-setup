# Subagent output contracts

How `coder` and `reviewer` return work to main agent, and how main agent classifies and routes the result.

---

## Coder return contract

`coder` must return these fields. Treat a missing field as an incomplete hand-off and ask before proceeding.

- `branch_name` — e.g. `feature/phase-2.2-slug`
- `head_sha` — SHA of the latest commit on that branch
- `files_touched` — list of paths created or modified
- `summary_for_operator` — **2-3 lines describing what changed and any decisions made beyond the brief**. Main agent relays this verbatim to the operator before invoking reviewer (sync gate, see `pipeline.md`).
- `build_trace` — the completed task trace, ready to paste into the PR body
- `local_checks_attempted` — explicit list of every gate command attempted, with exit code and either pass/fail/sandbox-block status for each. No silent skips.
- `local_checks` — final summary (lint/type/test/audit pass/fail). Must match what's in `local_checks_attempted`.
- `open_questions` — anything ambiguous the coder hit; non-empty means main agent must adjudicate before invoking reviewer.

### Classifying `open_questions`

If `open_questions` is non-empty, classify each item:

- **PLAN-vs-REQUIREMENTS-vs-DESIGN discrepancy** → escalate to the operator (see `escalation.md`). Mark the todo `[blocked] awaiting operator: <question>` and stop.
- **Under-specified but resolvable** → answer it from canonical sources, append the answer to the original brief, re-task coder.

---

## Reviewer return contract

`reviewer` returns one of two shapes.

### Shape A — clean

```yaml
status: opened
pr_number: <N>
pr_url: <url>
gate_environment:
  NO_COLOR: <value or "unset">
  FORCE_COLOR: <value or "unset">
  TERM: <value>
  container_image: <image or "host">
ci_local: { lint: pass, type: pass, test: pass, coverage: 0.78 }
adjacent_surfaces_scanned: <yes — what was checked>
notes: <optional>
```

The `gate_environment` field is mandatory in Shape A — reviewer must explicitly pin and document the env it ran gates in. Divergence from CI's env (different NO_COLOR setting, different TTY behaviour) historically produced reviewer-greens that CI rejected.

### Shape B — deviations OR sandbox-block

```yaml
status: rejected
deviations:
  - file: src/foo/bar.py
    line: 42
    plan_ref: PLAN.md §X.Y
    issue: <description>
    severity: blocking | nit
local_checks_failed: [test]   # or [sandbox_block] if the reviewer's gate couldn't run
suggested_fix: <advisory>
```

### Shape B decision tree

1. **All deviations blocking + factually clear** → send coder a tight delta brief (same coder instance, in-progress PR): *"PR N.M revision. Fix these specific items: `<list>`. Branch unchanged. Do not redo already-correct work."* Then re-invoke reviewer.
2. **`local_checks_failed: [sandbox_block]`** → treat as red. Either re-spawn a fresh reviewer in a different environment, or open the PR and use CI as the authoritative gate (note this explicitly in the PR body).
3. **Any deviation is a PLAN-vs-REQUIREMENTS-vs-DESIGN discrepancy** → escalate to operator with the exact text of both documents. Mark todo `[blocked] awaiting operator`. Do not proceed.
4. **Nit-only deviations** → instruct reviewer to open the PR; note the nits in the PR body. Do not gate on style nits.

If reviewer rejects the same PR twice with the same root cause, escalate to the operator — the brief is likely the problem.

---

## Pre-merge scope check (with doc-drift enforcement)

Before squash-merging a reviewer-opened PR, run `git diff --stat <base>...HEAD` and confirm:

1. **File scope.** Touched files match the brief's file list. Anything outside is a scope question: bounce to `reviewer` for explanation before merging.
2. **Doc drift.** If the PR changes anything that REQUIREMENTS / DESIGN / per-project CLAUDE.md describes (file paths, env vars, schema fields, CLI commands, run/test/build commands, integration contracts), verify the corresponding doc was updated in the same diff. **No "doc fix in a follow-up PR" exceptions.** If the doc update is missing, send a doc-update delta back to coder before merging.

Trust `reviewer` for title/body/template adherence — that's its contract. Trust `senior-reviewer` for release-readiness at `dev` → `master` cut time. Do not re-verify either here.

If scope is clean and doc drift is zero → `gh pr merge --squash --delete-branch`.
