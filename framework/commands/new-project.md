---
description: Bootstrap a new project at ~/workspace-bruno/<name>/. Main agent runs the requirements interview directly (brief-first, turn-by-turn Q&A); the operator approves REQUIREMENTS.md before Bruno authors DESIGN.md and PLAN.md.
---

The operator has requested a new project: **$ARGUMENTS**

Per master CLAUDE.md §6 / pipeline.md and the new-project bootstrap flow, follow these steps:

1. **Validate the target.**
   - Compute target path: `~/workspace-bruno/$ARGUMENTS/` (or `$CLAUDE_WORKSPACE_ROOT/$ARGUMENTS/` if overridden).
   - If the directory exists and is non-empty, stop and ask the operator how to proceed (different name, overwrite, etc.). Do not proceed silently.
   - If the directory is missing, you'll create it after confirmation.

2. **Confirm with the operator.** State:
   - Target project: `$ARGUMENTS`
   - Target path: `~/workspace-bruno/$ARGUMENTS/`
   - Any warnings from step 1.
   - Ask: "Confirm? [y/n]"

3. **On confirmation:**
   - `mkdir -p ~/workspace-bruno/$ARGUMENTS/`
   - `cd ~/workspace-bruno/$ARGUMENTS/` (this is the slash-command `cd` exception per `framework/docs/execution-policy.md`).
   - Initialize git if appropriate (`git init`; create `master` and `dev` branches per the bootstrap pattern in `framework/docs/new-project.md`).
   - Run the requirements interview yourself per `framework/docs/requirements.md` — mode: `fresh`, project_path: `~/workspace-bruno/$ARGUMENTS/`.
   - Your FIRST message to the operator must be the verbatim brief prompt: "Before we dive in, share a brief: what are you building, who is it for, and what's the most important thing I should know going in?" Subsequent questions are brief-aware, one focused question per turn.

4. **After the interview reaches the approval gate (per requirements.md §8):**
   - Surface the concise summary (sections populated, TBDs, recommended next step) to the operator.
   - Ask: "Approve `REQUIREMENTS.md` and proceed to DESIGN/PLAN? Or revise specific sections?"
   - On approve → author DESIGN.md (only if external integrations declared) and PLAN.md per `framework/docs/design.md` and `framework/docs/plan.md`.
   - On revise → re-enter interview mode for only the named sections; do not redo sections the operator didn't touch.

5. **Only after the operator approves all three docs (REQUIREMENTS, DESIGN where applicable, PLAN)** → invoke `scaffolder` for the initial scaffold commit.

6. **On rejection / silence at any approval gate:**
   - Stay where you are. Do not advance.

Do not author DESIGN.md or PLAN.md before the operator approves REQUIREMENTS.md. Do not invoke `scaffolder` before the operator approves all three docs. The approval gates are load-bearing.
