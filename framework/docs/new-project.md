# `/new-project` bootstrap

How Bruno bootstraps a fresh project. The full pipeline (requirements interview → design → plan → scaffold → code → review → docs → PR → merge) is documented in `pipeline.md`; this doc covers the **GitHub-repo bootstrap** and **requirements interview kickoff** that happen at the very start.

---

## Order of operations

1. **Validate the target.** Compute `~/workspace-bruno/<name>/` (or `$CLAUDE_WORKSPACE_ROOT/<name>/` if overridden). If the directory exists and is non-empty, stop and ask the operator how to proceed.
2. **Confirm with the operator.** Show the target path + any warnings; ask "Confirm? [y/n]".
3. **Create the directory + init git** (see GitHub repo bootstrap below).
4. **Run the requirements interview directly** per the `requirements.md` playbook — mode: `fresh`. First turn asks the operator for a brief, then runs turn-by-turn Q&A, writing `docs/REQUIREMENTS.md` incrementally.
5. **Approval gate.** When the interview is complete, surface a concise summary (sections populated, TBDs, recommended next step) and ask the operator: "Approve REQUIREMENTS.md and proceed to DESIGN/PLAN? Or revise specific sections?"
6. **On approve:** main agent authors `docs/DESIGN.md` (only if external integrations were declared in REQUIREMENTS §3) and `docs/PLAN.md`.
7. **On revise:** re-enter interview mode for only the named sections; do not redo sections the operator didn't touch.
8. **Only after the operator approves all three docs** (REQUIREMENTS, DESIGN where applicable, PLAN) → invoke `scaffolder` for the initial scaffold commit.

Don't author DESIGN.md or PLAN.md before the operator approves REQUIREMENTS.md. Don't invoke `scaffolder` before the operator approves all three docs. The approval gates are load-bearing.

---

## GitHub repo bootstrap

- All repos live under the operator's personal GitHub account.
- `gh` CLI is already authenticated.
- During `/new-project`: check if a repo with that name already exists on GitHub.
  - **If yes:** clone it into `~/workspace-bruno/<name>` and check out the `dev` branch. If the repo does not have a `dev` branch, **stop immediately** and tell the operator — do not fall back to `master`, do not create `dev`.
  - **If no:** create local repo and remote with both `master` (initial empty commit) and `dev` (branched off `master`), push both, and set `dev` as the GitHub default branch (`gh repo edit <name> --default-branch dev`).

---

## Single-branch exception

The `claude-setup` and `bruno-setup` repos are single-branch — only `master`. No `dev` branch, no feature branches, no PRs, no release process. Work commits and pushes directly to `master`. No other project gets this exception without explicit operator direction.
