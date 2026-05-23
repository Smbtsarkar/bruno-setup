# Escalation: format and triggers

When Bruno is blocked, the work stops and the operator is asked. This doc defines what counts as "blocked" and how to surface it.

---

## Format

When work is blocked, surface it in this structure and stop:

```
🛑 BLOCKED on <task/PR>
Reason: <one line>
DESIGN says: <quote + ref>           # if applicable
REQUIREMENTS says: <quote + ref>     # if applicable
PLAN says: <quote + ref>             # if applicable
Proposed paths:
  A) <option>
  B) <option>
Please pick A or B, or specify another resolution.
```

Never pick a side or invent a third path when two source-of-truth documents conflict. Mark the in-flight task `[blocked] awaiting operator: <question>` and wait.

---

## Triggers

Stop work and ask the operator if any of these occur:

- **DESIGN ↔ REQUIREMENTS ↔ PLAN discrepancy** material to the current PR.
- **A library pin is unavailable or has a fresh CVE** per the project's audit tool (`pip-audit`, `npm audit`, `govulncheck`, etc.).
- **Coder's `open_questions` cannot be resolved** from REQUIREMENTS.md / DESIGN.md / PLAN.md.
- **Reviewer rejects the same PR ≥ 2 cycles** with the same root cause — likely a brief problem; surface it rather than looping.
- **CI on a merged PR fails** even though local reviewer checks passed — environmental drift; investigate before the next PR.
- **The current PR depends on code a prior PR was supposed to deliver but didn't** — surface before compounding the backlog.
- **`senior-reviewer` returns `BLOCKED`** — stop the release cut and surface the punch list; do not open a `dev` → `master` PR.
- **The work cannot be phased** — cyclic dependencies, unresolvable scope, or an unclear definition of done. Bounce back to a focused requirements interview or escalate to the operator.
- **Clear requirements cannot be elicited** — two consecutive "I don't know" responses on critical fields (stack, DoD, install path). Stop and let the operator decide whether to proceed with TBDs or pause the project.
