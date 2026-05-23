# Plan playbook

Main agent uses this when writing `docs/PLAN.md` for a project. The PLAN.md is the build script — every PR Bruno will ship to deliver the REQUIREMENTS, in order.

PLAN.md is written **after** REQUIREMENTS.md and (if external integrations exist) DESIGN.md. PLAN doesn't introduce new requirements — it sequences existing ones into PRs.

---

## 0. Before you write PLAN.md

Confirm these exist and are approved:

- `docs/REQUIREMENTS.md` — populated per `~/.claude/docs/requirements.md`.
- `docs/DESIGN.md` — if any external integrations declared, populated per `~/.claude/docs/design.md`.

If either is missing, write/fix it first. PLAN cannot exist without REQUIREMENTS to deliver and DESIGN to implement.

---

## 1. PLAN.md structure

```markdown
# <Project> — PLAN.md (v1)

## 0. Hard Rules
<branch model, commit format, PR template ref, version pin philosophy>

## 1. Library Choices
<runtime deps with version pins + justification; dev deps; forbidden libraries with reason>

## 2. Project Structure
<directory tree, ~50 lines, shows expected layout end-state>

## 3. Phase + PR Plan
<the actual build script — see template below>

## 4. Testing Strategy
<unit / integration / install-gate / e2e layers and what each covers>

## 5. Release Strategy
<tag-driven vs PR-driven, release.yml flow, install-gate gating>
```

The load-bearing section is **§3 Phase + PR Plan**.

---

## 2. Phase + PR template

Each phase is a logical grouping (Phase 0 = scaffold, Phase 1 = first vertical slice, etc.). Each phase contains one or more PRs.

```markdown
### Phase N — <name>

- **PR N.M** — <one-line title>
  - **Files:**
    - `path/to/file1.py` (new)
    - `path/to/file2.py` (modify)
  - **Reads from DESIGN:** §<section> (cite specific lifecycle / sequence / source-of-truth)
  - **Reads from REQUIREMENTS:** §<section> (cite specific capability)
  - **Unit tests required:**
    - `tests/unit/test_<module>.py::test_<behaviour>` — what it asserts
    - (one bullet per test)
  - **Integration tests required:**
    - `tests/integration/test_<flow>.py::test_<scenario>` — what it asserts
  - **Operator-runs-this test:**
    ```bash
    # Concrete commands an operator can paste to verify this PR works end-to-end.
    # NOT "run the unit tests" — that's the gate's job.
    # This is the operator-simulation: install the artifact, exercise the new capability, verify the expected output.
    ```
  - **Acceptance criteria:**
    - [ ] <each one independently verifiable; copied verbatim into the PR body>
  - **Port from:** <reference codebase if porting, otherwise "net-new — design from DESIGN §X">
```

Every PR has every field. Missing fields are signals that the planning is incomplete, not that the field is optional.

### Why each field exists

- **Files** — sets the scope. Reviewer uses this to detect drive-by edits.
- **Reads from DESIGN / REQUIREMENTS** — forces the coder to consult canonical sources. If a PR can't cite specific sections, either the docs are too thin or the PR isn't well-scoped.
- **Unit tests required** — pre-commits to what's verifiable in isolation. Test-driven scoping; tests aren't a follow-up PR.
- **Integration tests required** — covers what unit tests can't (cross-module behaviour, real I/O paths).
- **Operator-runs-this test** — the install-gate concept at PR granularity. Catches install/UX bugs at PR-merge time, not at release time. PRs without an operator-simulation test are how install-bug classes ship to operators undetected.
- **Acceptance criteria** — copied into the PR body so it's verifiable at PR review time. Each criterion has a true/false answer.
- **Port from** — citation for the coder. "Port from `~/workspace-bruno/<other>/src/<module>.py`" is the highest-leverage form of brief — much faster than designing from scratch.

---

## 3. Phase gate definition

End of each phase = **install works on clean container/VM**, not just unit tests green. See master CLAUDE.md §15 / deployment-gate.md.

- Per-PR: `scripts/dev/install-gate.sh` (or stack equivalent) runs in CI as part of the PR's `Live install dry-run` job. Must pass before merge.
- Per major-milestone phase: a real-VM smoke test using the documented install flow from README. Operator runs this (or CI runs a longer-form Docker job).

Phase isn't done until the gate passes. No exceptions.

---

## 4. Library choice format

```markdown
| Library | Pin | Why |
|---------|-----|-----|
| `discord.py` | `>=2.4,<3.0` | Discord SDK with async + slash command support; vetted, maintained |
| `claude-agent-sdk` | `>=0.1.0,<1.0` | Required for agent orchestration |
```

Pins are **range pins** (`>=X,<Y`), not exact pins, unless a CVE or upstream bug forces exact pin temporarily.

Forbidden libraries get their own table with reason — surfaces "don't use X because Y" so future PRs don't accidentally reintroduce.

---

## 5. Brief extraction

When a PR's time comes, main agent extracts a brief from the PLAN.md entry. The brief is **pointer + delta**, not standalone:

```
PR N.M (per PLAN.md §3 Phase N).

Files: <copy from PLAN.md>
Reads from DESIGN: <copy>
Reads from REQUIREMENTS: <copy>
Unit tests required: <copy>
Integration tests required: <copy>
Operator-runs-this test: <copy>
Acceptance criteria: <copy>
Port from: <copy>

Notes for this PR specifically: <any delta context the coder needs, e.g. "the prior PR introduced X, this PR uses it differently because Y">
```

Default cap: 40 lines (master CLAUDE.md §6 brief discipline). If the brief exceeds 40 lines, the missing context belongs in DESIGN, not the brief.

---

## 6. Update discipline

PLAN.md is a **living doc**, not a frozen artifact. Update it when:

- New PRs are discovered mid-phase (add the PR to the phase, with a note explaining why it wasn't in the original plan).
- A PR's scope changes (update the Files / Tests / Acceptance fields).
- A phase splits or merges (update phase boundaries).

If PLAN.md doesn't reflect the work being done, that's a bug. Senior-reviewer treats PLAN-vs-actual drift as LOOSE END (or BLOCKER if material to the current release).

---

## 7. After PLAN.md is approved

1. Surface PLAN.md to operator. Get explicit approval before any code lands.
2. Begin PR 0.1 (or wherever the plan starts). Extract brief per §5. Spawn `coder` (or `scaffolder` for the initial scaffold PR).
3. Per PR: `coder` → main-agent sync gate (relay `summary_for_operator`) → `reviewer` (per-phase) → next PR.
4. End of phase: `reviewer` (comprehensive) + install-gate must pass before moving to next phase.
