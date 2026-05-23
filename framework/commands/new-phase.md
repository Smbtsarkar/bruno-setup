---
description: Add a new phase (set of features) to an existing project. Bruno reads docs/REQUIREMENTS.md, infers the next phase number from the highest existing phase, asks for a phase-tagged brief, creates a feature branch off `dev`, bootstraps §11 Phase Log if missing, and conducts a focused delta interview before authoring DESIGN/PLAN deltas.
---

The operator has requested a new phase. Optional argument **$ARGUMENTS** may name the phase intent (free text), but is not required.

Per master CLAUDE.md §6 / pipeline.md / requirements.md, follow these steps. **All REQUIREMENTS.md edits MUST happen on the new feature branch (step 5)** — never on `master` or `dev`.

1. **Verify the project is initialized + pre-branch hygiene.**
   - Confirm `docs/REQUIREMENTS.md` exists at the project root. If not, stop and tell the operator: "No `docs/REQUIREMENTS.md` here. Run `/new-project <name>` first, or `cd` into an initialized project."
   - Confirm the working tree is clean (`git status --porcelain` is empty). If not, stop: "Uncommitted changes detected. Commit or stash first, then re-run `/new-phase`." Do **not** auto-stash — risk of losing operator work.
   - Note the current branch:
     - If `master` or `dev` → Bruno will auto-create a `feat/phase-N+1-<slug>` branch in step 5. Continue.
     - If anything else (already on a feature branch) → ask the operator once: *"Currently on `<branch>`. Create new `feat/phase-N+1-<slug>` from `dev` for this phase, or stay on this branch and add Phase N+1 here?"* Record the answer for step 5.

2. **Detect the next phase number.**
   - `grep -oE '(^|\s|#)\s*[Pp]hase\s+([0-9]+)' docs/REQUIREMENTS.md` and take the highest captured number. Sources to scan:
     - `<!-- BRIEF (Phase N): ... -->` markers (current convention).
     - `<!-- BRIEF: ... # Phase N: ... -->` markers (original-project convention, from `/new-project`).
     - `### Phase N` headings under `## 11. Phase Log` if it exists.
     - `Phase N` mentions in §2 Capabilities CAP-N.X naming, if used.
   - If no phase reference is found anywhere, treat the existing REQUIREMENTS.md as **Phase 1** (the original `/new-project` baseline) and propose **Phase 2** as the next.
   - State the inferred number to the operator: *"REQUIREMENTS.md's highest existing phase is N. Next phase will be N+1. Proceed? [y/n]"*
   - Note whether `## 11. Phase Log` exists; you'll bootstrap it in step 6 if missing.

3. **Confirm Phase N+1 with the operator.** Wait for `y`/yes/proceed before continuing. On `n`/cancel/silence, stop here — no branch created, no file edits.

4. **Ask for the phase-tagged brief.** Your message to the operator, verbatim:

   > *"Brief for Phase N+1 — what does this phase add, change, or cut? Free text. Please mark with `# Phase N+1:` at the top so we record the right phase number."*

   Wait for the operator's reply. **Do not write to any file yet** — the brief lives in memory until step 6.

   - If the operator's brief doesn't start with `# Phase N+1:` or names a different number, ask once: *"Brief doesn't mark `# Phase N+1:` — confirm we're capturing this as Phase N+1, or pick a different number?"* Then accept their answer.
   - Extract the **short title** for the phase (a 3–6 word summary of intent). If the brief doesn't give one cleanly, ask one focused follow-up turn for it before proceeding.

5. **Create the feature branch** (skip if the operator chose "stay on current branch" in step 1).
   - Derive `<slug>` from the short title: lowercase, replace non-alphanumeric with `-`, collapse repeated `-`, strip leading/trailing `-`, truncate to 40 chars. Example: short title `"Add admin commands & multi-user"` → slug `add-admin-commands-multi-user`.
   - Branch name: `feat/phase-N+1-<slug>` (e.g. `feat/phase-2-add-admin-commands-multi-user`).
   - Run in this order:
     ```bash
     git checkout dev
     git pull --ff-only origin dev    # best effort; if no remote `dev` or no network, log and continue
     git checkout -b feat/phase-N+1-<slug>
     ```
   - State the new branch name to the operator in one line: *"Created `feat/phase-N+1-<slug>` off `dev`."*
   - If any git command fails (e.g. `dev` doesn't exist, merge conflicts, detached HEAD), stop and surface the error. Do **not** start REQUIREMENTS.md edits — that work belongs on the feature branch only.

6. **Bootstrap §11 Phase Log if missing** (now on the feature branch).
   - If `docs/REQUIREMENTS.md` has no `## 11. Phase Log` section, append it. Use this skeleton:

     ```markdown
     ## 11. Phase Log

     Chronological record of phases added via `/new-phase`. Each phase keeps its verbatim brief and a delta summary. The capability/integration/install/data details land in §1–§10 in place; this section is the brief archive + diff trail.

     ### Phase 1 — original baseline
     <!-- BRIEF (Phase 1): (see top-of-file BRIEF marker for verbatim) -->
     Delta: original `/new-project` baseline; see §1–§10 for full surface.
     ```

   - Only do this on first `/new-phase` for the project. After that, §11 already exists.

7. **Append `### Phase N+1 — <short title>` to §11** with the operator's brief recorded verbatim:

   ```markdown
   ### Phase N+1 — <short title from step 4>
   <!-- BRIEF (Phase N+1): <verbatim operator reply from step 4> -->
   Delta:
   <!-- (filled in as the delta interview progresses in step 8) -->
   ```

8. **Conduct the focused delta interview** per `requirements.md` §5 — but only ask about REQUIREMENTS sections this phase touches:
   - New capabilities → append `CAP-N+1.001`, `CAP-N+1.002`, etc. under §2.
   - New external integrations → append new `INT-XXX` blocks under §3.
   - Changes to existing integrations (new auth model, credential rotation, etc.) → amend the existing §3.X in place AND note the change in `### Phase N+1`'s delta summary.
   - Changes to install steps → amend §4 in place.
   - New sources of truth → append rows to §5 table.
   - Data layer changes → amend §7 in place; note in delta.
   - Non-functional changes → amend §8 in place.
   - Phase-specific out-of-scope items → append under §9 with phase tag.
   - License change → not a phase concern; defer.

   Write incrementally: `Edit` each affected section as soon as its Q&A is done. Update `### Phase N+1`'s delta summary in §11 in parallel so the diff trail stays in sync.

9. **Approval gate** (per `requirements.md` §8, new-phase summary):
   - Surface a concise summary:
     ```
     Phase N+1 captured on feat/phase-N+1-<slug>.
     New capabilities: CAP-N+1.001, ...
     Touched sections: §3 (new integration INT-XXX), §4 (added step 5), §5 (added 2 rows), §7 (schema change).
     Untouched: §1, §2 pitch, §6, §8, §9, §10.
     TBDs:
       - §X.Y: <one-line reason>
     Recommend: approve and proceed to DESIGN/PLAN deltas, OR revise specific sections.
     ```
   - Ask: *"Approve Phase N+1 in REQUIREMENTS.md and proceed to DESIGN/PLAN updates? Or revise specific sections?"*
   - **On approve:** author DESIGN.md deltas (only if the phase changes lifecycles, sources of truth, or error contracts) and PLAN.md deltas (a new `## Phase N+1` section appended) per `framework/docs/design.md` and `framework/docs/plan.md`.
   - **On revise:** re-enter delta interview mode for the named sections only.
   - **On rejection / silence:** stay on the feature branch. Do not advance to DESIGN/PLAN authoring. The branch + WIP edits remain so the operator can resume later or delete the branch if abandoning.

10. **No scaffolder.** `/new-phase` does NOT re-invoke `scaffolder` — the project is already scaffolded. After DESIGN/PLAN deltas are approved, the flow continues with `coder` per the standard pipeline (per-phase commits, sync gate, reviewer, etc.).

Do not author DESIGN.md or PLAN.md deltas before the operator approves the new Phase N+1 entry in REQUIREMENTS.md. The approval gate is load-bearing — same as `/new-project`.
