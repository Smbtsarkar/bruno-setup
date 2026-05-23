# `/new-project` bootstrap

How Bruno bootstraps a fresh project. The full pipeline (interview → design → plan → scaffold → code → review → docs → PR → merge) is documented in `pipeline.md`; this doc covers the **GitHub-repo bootstrap** that happens at the very start.

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
