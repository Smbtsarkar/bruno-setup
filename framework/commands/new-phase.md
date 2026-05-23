---
description: Add a new phase (set of features) to an existing project. Bruno reads docs/REQUIREMENTS.md, infers the next phase number from the highest existing phase, bootstraps §11 Phase Log if missing, prompts for a phase-tagged brief, and conducts a focused delta interview before authoring DESIGN/PLAN deltas.
---

The operator has requested a new phase. Optional argument **$ARGUMENTS** may name the phase intent (free text), but is not required.

Per master CLAUDE.md §6 / pipeline.md / requirements.md, follow these steps:

1. **Verify the project is initialized.**
   - Confirm `docs/REQUIREMENTS.md` exists at the project root. If not, stop and tell the operator: "No `docs/REQUIREMENTS.md` here. Run `/new-project <name>` first, or `cd` into an initialized project."
   - Confirm the working branch is not `master` or `dev` directly (per pipeline.md pre-flight checks). If it is, stop and ask the operator to create a feature branch first (suggested: `feat/phase-N-<short-desc>`, where N is the next phase number).

2. **Detect the next phase number.**
   - `grep -oE '(^|\s|#)\s*[Pp]hase\s+([0-9]+)' docs/REQUIREMENTS.md` and take the highest captured number. Sources to scan:
     - `<!-- BRIEF (Phase N): ... -->` markers (current convention).
     - `<!-- BRIEF: ... # Phase N: ... -->` markers (original-project convention, from `/new-project`).
     - `### Phase N` headings under `## 11. Phase Log` if it exists.
     - `Phase N` mentions in §2 Capabilities CAP-N.X naming, if used.
   - If no phase reference is found anywhere, treat the existing REQUIREMENTS.md as **Phase 1** (the original `/new-project` baseline) and propose **Phase 2** as the next.
   - State the inferred number to the operator: *"REQUIREMENTS.md's highest existing phase is N. Next phase will be N+1. Proceed? [y/n]"*

3. **Bootstrap §11 Phase Log if missing.**
   - If `docs/REQUIREMENTS.md` has no `## 11. Phase Log` section yet, append one BEFORE asking for the brief. Use this skeleton:

     ```markdown
     ## 11. Phase Log

     Chronological record of phases added via `/new-phase`. Each phase keeps its verbatim brief and a delta summary. The capability/integration/install/data details land in §1–§10 in place; this section is the brief archive + diff trail.

     ### Phase 1 — <inferred or "original baseline">
     <!-- BRIEF (Phase 1): <copy the existing top-of-file BRIEF marker contents here, or "(see <!-- BRIEF --> marker at top of file)" if you want to leave the original marker as the source of truth> -->
     Delta: original `/new-project` baseline; see §1–§10 for full surface.
     ```

   - Only do this on first `/new-phase` for the project. After that, §11 already exists and you just append a new `### Phase N+1` entry.

4. **Run the requirements interview in `new-phase` mode** per `framework/docs/requirements.md` §2.
   - Your FIRST message to the operator must be the verbatim phase-brief prompt:

     > *"Brief for Phase N+1 — what does this phase add, change, or cut? Free text. Please mark with `# Phase N+1:` at the top so we record the right phase number."*

   - Wait for the operator's reply. Record the entire reply verbatim as `<!-- BRIEF (Phase N+1): <verbatim> -->` inside a new `### Phase N+1 — <short title>` subsection appended to §11.
   - The short title is the operator's one-line summary of the phase intent — extract it from the brief, or ask in one focused follow-up turn if the brief doesn't give one.
   - If the operator's brief doesn't start with `# Phase N+1:` or names a different number, ask once: *"Brief doesn't mark `# Phase N+1:` — confirm we're capturing this as Phase N+1, or pick a different number?"* Then accept their answer.

5. **Conduct the focused delta interview** per requirements.md §5 — but only ask about sections this phase touches:
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

6. **Approval gate** (per requirements.md §8, adapted for phase mode):
   - Surface a concise summary:
     ```
     Phase N+1 captured.
     New capabilities: CAP-N+1.001, ...
     Touched sections: §3 (new integration INT-XXX), §4 (added step 5), §5 (added 2 rows), §7 (schema change).
     TBDs:
       - §X.Y: <one-line reason>
     Recommend: approve and proceed to DESIGN/PLAN deltas, OR revise specific sections.
     ```
   - Ask: *"Approve Phase N+1 in REQUIREMENTS.md and proceed to DESIGN/PLAN updates? Or revise specific sections?"*
   - **On approve:** author DESIGN.md deltas (only if the phase changes lifecycles, sources of truth, or error contracts) and PLAN.md deltas (a new `## Phase N+1` section appended) per `framework/docs/design.md` and `framework/docs/plan.md`.
   - **On revise:** re-enter interview mode for the named sections only.
   - **On rejection / silence:** stay where you are. Do not advance to DESIGN/PLAN authoring.

7. **No scaffolder.** `/new-phase` does NOT re-invoke `scaffolder` — the project is already scaffolded. After DESIGN/PLAN deltas are approved, the flow continues with `coder` per the standard pipeline (per-phase commits, sync gate, reviewer, etc.).

Do not author DESIGN.md or PLAN.md deltas before the operator approves the new Phase N+1 entry in REQUIREMENTS.md. The approval gate is load-bearing — same as `/new-project`.
