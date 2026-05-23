# Requirements interview playbook

This doc is **Bruno's playbook for running the requirements interview himself.** It defines the brief-first flow, turn-by-turn question script, and the REQUIREMENTS.md output template.

Audience: Bruno (the main agent). The interview is no longer delegated to a subagent — Bruno conducts it directly, then authors DESIGN.md and PLAN.md from the same context once the operator approves what was captured.

---

## 1. Role and pacing

- **Brief-first.** The first message to the operator is always the brief prompt (§3 below). Wait for the operator's reply. Record it verbatim.
- **Turn-by-turn.** One focused question per turn. After each operator answer, summarize in one line ("So: <X>. Moving on."), then ask the next question. No batching, no multi-part questions.
- **Probe vague answers exactly once.** Second-pass vague = accept as TBD and move on.
- **Operator owns the pace.** "Skip this section", "let me revise §2", "I want to stop here" — all valid. Adapt.
- **Write incrementally — section by section.** After the brief arrives, do a single `Write` to lay down the skeleton (brief marker + empty section headers + WIP marker on §1). From there, `Edit` the file as soon as each section's Q&A is done. Never let two completed sections accumulate before writing. The whole point is that mid-interview missteps don't lose prior work.
- **Stay in interview mode until the operator approves §10.** Do not slip into DESIGN/PLAN authoring mid-interview, even if the answers are obviously sufficient. The approval gate is load-bearing.

---

## 2. Operating modes

Pick mode at the start, surface it to the operator, and don't switch mid-interview:

- **`fresh`** — full interview from blank slate. No existing REQUIREMENTS.md, or the operator chose full re-interview. Triggered by `/new-project` or `!new-project`.
- **`focused-update`** — read existing `docs/REQUIREMENTS.md`; ask only about the sections the operator named (e.g. "§3 Integrations" and "§5 Sources of Truth"). Skip the rest. Triggered when the operator asks to update specific REQUIREMENTS sections without adding a new phase.
- **`new-phase`** — read existing `docs/REQUIREMENTS.md`; infer the next phase number from existing phase markers; conduct a focused **delta** interview for the new phase. Append to `## 11. Phase Log` AND update §1–§10 in place. Triggered by `/new-phase` or `!new-phase`. Full procedure in `framework/commands/new-phase.md`.

For existing-project flows where the operator's intent is unclear, **ask first** before the brief prompt: *"REQUIREMENTS.md exists. Focused update on specific sections, add a new phase (`/new-phase`), or full re-interview?"*

**Brief-first applies to all modes.** Frame the brief prompt per mode:

- `fresh`: *"Before we dive in, share a brief: what are you building, who is it for, and what's the most important thing I should know going in?"*
- `focused-update`: *"Quick brief first: what's changed since the last interview, or what would you like to focus on?"*
- `new-phase`: *"Brief for Phase N+1 — what does this phase add, change, or cut? Free text. Please mark with `# Phase N+1:` at the top so we record the right phase number."* (N is the highest existing phase; see `framework/commands/new-phase.md` for inference logic.)

---

## 3. Brief intake

The first message to the operator, **verbatim** (fresh mode):

> *"Before we dive in, share a brief: what are you building, who is it for, and what's the most important thing I should know going in? Free text — as much or as little as you want."*

In `focused-update` mode:

> *"Quick brief first: what's changed since the last interview, or what would you like to focus on?"*

In `new-phase` mode (N is the highest existing phase, inferred per `framework/commands/new-phase.md`):

> *"Brief for Phase N+1 — what does this phase add, change, or cut? Free text. Please mark with `# Phase N+1:` at the top so we record the right phase number."*

**Wait for their reply. Don't ask other questions yet.**

Once received, record verbatim:

- `fresh` mode → first line of REQUIREMENTS.md:
  ```html
  <!-- BRIEF: <verbatim operator reply> -->
  ```

  Recommended brief format (operator's free choice, but encouraged): pitch paragraph, then `# Phase 1:` followed by bulleted feature list, then any references / specifics. The `# Phase N:` heading inside the brief is what lets later `/new-phase` runs infer the next phase number.

- `focused-update` mode → no new BRIEF marker; the existing one stays. Capture the operator's focus instructions in a transient note for your own use during the interview.

- `new-phase` mode → inside the new `### Phase N+1 — <title>` subsection of §11 Phase Log:
  ```html
  <!-- BRIEF (Phase N+1): <verbatim operator reply> -->
  ```

  Same recommended format as fresh-mode briefs, but the `# Phase N+1:` heading is **mandatory** so the phase number is unambiguous. If the operator's brief doesn't include it, ask once for confirmation of the phase number.

---

## 4. Parsing the brief

After receiving the brief, mark each REQUIREMENTS.md section (§0 Conventions through §10 License) as one of:

- **covered** — the brief explicitly answers it (e.g. "one-sentence pitch" is clearly in the brief). Skip the question for this section.
- **partial** — the brief hints at it but doesn't fully answer (e.g. brief mentions "Discord bot" but not the auth model). Ask a targeted probe question instead of the full open question.
- **uncovered** — the brief doesn't mention it. Ask the cold question.

Be conservative — if you're not sure whether the brief covers a section, treat it as partial and probe.

---

## 5. Question script

Sections follow the REQUIREMENTS.md output-template order. Each entry below has:
- The cold question (what to ask if uncovered).
- The probe (what to ask if partial).
- The skip condition (what counts as covered).
- TBD acceptance criteria (what to accept after one probe).

**In `new-phase` mode, scope the question script to deltas only.** For each section §1–§9, ask only one targeted phase-delta question first; skip the full cold question if the operator answers "no change to §X". Example:

> *"Phase N+1 §3 Integrations — does this phase add a new external system, change an existing integration's auth model, or change credential ownership? If no, we'll skip §3."*

If the operator says "yes, X changes", drop into the standard §3 cold/probe flow for the changed integration only. If "no", move on to §4. Track touched sections — the approval-gate summary lists them explicitly.

### §1 — Pitch + system topology

**Cold:** "In one sentence: what is this project, who uses it, what does it do? (e.g. 'A CLI tool that lets developers back up their dotfiles to encrypted Google Drive.')"

**Probe:** "OK, you mentioned <X>. Who specifically uses it — just you? A small team? Distributed users? And what's the deployment shape — single binary on a laptop? Service on a VM? Container?"

**Skip if:** brief states (1) what the project does, (2) who uses it, (3) where it runs.

**TBD if:** operator can't name the deployment target (OS + runtime + container if any) after one probe. Mark `<!-- TBD: deployment target unspecified -->` in §1.

### §2 — Capabilities (v1)

**Cold:** "What does the software do at v1? List capabilities, one per line. We'll number them CAP-001, CAP-002, etc. for traceability."

**Probe:** "The brief mentions <X> and <Y> — anything else for v1? Or is that the full surface?"

**Skip if:** brief gives an enumerated capability list.

**TBD if:** operator says "I'll figure it out as I go" after probe. Note: this is a strong signal the project isn't ready for design — flag in `open_questions` as a real blocker, not just a TBD.

### §3 — External integrations

For **each** external system the operator names (Discord, Slack, Google APIs, OAuth providers, payment APIs, MCP servers, third-party SDKs):

**Cold:** "Tell me about <integration>: what's the auth model (API key, OAuth, service account)? Who supplies the credential — operator brings it, or the harness generates it? Where does the credential live at runtime?"

**Probe:** "OK <auth model> — what happens if the credential is missing or invalid at runtime? Hard fail, warn-and-degrade, or block specific features only?"

**Skip if:** brief names the integration AND its auth model AND credential ownership.

**TBD if:** any of {auth model, credential owner, missing-credential behaviour} can't be answered after one probe. Mark inline and surface in `open_questions` — DESIGN.md §Lifecycles cannot be written without these.

**Operator says no integrations:** confirm explicitly ("So no external systems — no Discord, no databases beyond what your runtime gives you, nothing?"). If confirmed, §3 is "(none)" and DESIGN.md is not required (per CLAUDE.md §1, DESIGN.md is only mandatory when external integrations are declared).

### §4 — Operator Install & First-Run Experience (MANDATORY)

**Cold:** "Walk me through the operator's first install, step by step. Step 1: they open a clean OS install. What's the first command they type? (Continue until the service is running and they've used a feature.)"

**Probe:** if the operator gives a vague "they run setup.sh" — "What does setup.sh do? What files does it produce? What credentials does the operator have to bring? What happens if step 3 fails?"

**Skip if:** brief gives a concrete keystroke-by-keystroke walkthrough.

**TBD if:** operator can't sketch even the first 5 commands after probe. This is a strong signal the install path is undefined — flag in `open_questions` as a blocker for `setup.sh`.

This section is **mandatory** — REQUIREMENTS.md is incomplete without it. If the operator refuses to walk through it, log a blocker and stop.

### §5 — Sources of Truth (MANDATORY)

**Cold:** "For every fact your project will need to know at runtime — file paths, env var names, schema fields, credential locations, allowlists — which file is the authoritative source? I'll capture it as a table."

Show the operator the table shape:

```markdown
| Fact | Authoritative source | Read by | Written by |
|------|---------------------|---------|------------|
| <e.g. backup destination path> | `<file>:<field>` | `<reader component>` | `<writer or "operator (manual edit)">` |
```

**Probe:** if the operator says "config goes in a config file" — "Which config file? `/etc/<project>/config.toml`? `~/.<project>rc`? An env file? Who writes it — operator manually, or `setup.sh`?"

**Skip if:** brief includes a sources-of-truth table.

**TBD if:** operator names a fact but can't say where it lives or who writes it. Mark inline.

This section is **mandatory** — missing this is how projects ship source-of-truth conflicts.

### §6 — Inputs and Outputs

**Cold:** "What does the software ingest — file types, network protocols, user input shapes? And what does it produce — files, network responses, UI, side effects?"

**Probe:** "<X> in — got it. Format? Size limits? What happens on malformed input?"

**Skip if:** brief names inputs AND outputs concretely.

**TBD if:** operator can't name format or constraints after one probe. Mark inline.

### §7 — Data Layer (if applicable)

**Cold:** "Does the project persist any data? Database? Files on disk? In-memory only?"

**Probe:** "<DB or filesystem> — schema shape? Retention policy? Migrations?"

**Skip if:** brief says explicitly "no persistent data" OR brief names the data layer with a schema sketch.

**TBD if:** operator says "we'll figure out schema later" after probe. Note: this is reasonable for early-phase projects; mark `<!-- TBD: schema deferred to PLAN.md Phase N -->` and move on.

### §8 — Non-functional requirements

**Cold:** "Performance / latency / memory / disk targets? Platforms (OS, runtime versions, dependencies)? Security posture? Observability needs (logs, metrics, traces)?"

**Probe:** "OK, defaults are fine for most of these — anything you specifically care about? E.g. 'must handle 1000 requests/sec' or 'must run on a Raspberry Pi'?"

**Skip if:** brief states a specific non-functional constraint (e.g. "must work offline" or "p99 latency < 100ms").

**TBD if:** operator can't name a target after probe. Default to "no specific NFR targets — sensible defaults" and move on (this is fine; not a blocker).

### §9 — Out of scope (v1)

**Cold:** "What did you consider for v1 and explicitly decide to cut? Aim for at least three things — forces the boundary to be articulate."

**Probe:** if operator gives one cut item — "What else? What about <X> (extrapolated from the brief)?"

**Skip if:** brief lists explicit cuts.

**TBD if:** operator can't name anything cut after probe. Reasonable — log "no explicit cuts; scope = full feature list at §2".

### §10 — License

**Cold:** "License? MIT, Apache-2.0, GPL-3.0, proprietary?"

**Probe:** if operator says "whatever's default" — "MIT is the framework default. OK?"

**Skip if:** brief names a license.

**TBD if:** operator genuinely doesn't know after probe. Default to MIT and note `<!-- TBD: operator deferred license choice; defaulted to MIT -->`.

---

## 6. Anti-questions (NEVER ask)

These are planner / scaffolder concerns. If the operator asks about them during the interview, defer with: *"That's the planner's call; I'll record any preference you have, but the default-picking happens in PLAN.md."*

- ❌ Exact library versions (e.g. "should we use FastAPI 0.110 or 0.115?")
- ❌ Exact file paths inside the project (e.g. "should config live in `src/config/` or `app/config/`?")
- ❌ Test framework choice (pytest vs unittest vs node:test — planner picks per stack convention)
- ❌ CI provider (defaults to GitHub Actions)
- ❌ Code style / formatting conventions
- ❌ Database engine specifics beyond "SQL or document store" (planner picks Postgres/SQLite per stack)

If the operator volunteers a preference (e.g. "I want to use Postgres" or "no FastAPI"), record it in §8 Non-functional → "Stack constraints". Otherwise don't ask.

---

## 7. REQUIREMENTS.md output template

Populate `docs/REQUIREMENTS.md` with this structure. **Lay it down as a skeleton immediately after the brief arrives** (with all section headers present but bodies empty, plus a `<!-- WIP: <section> -->` marker on whichever section is currently being filled). `Edit` each section as soon as its Q&A is done.

```markdown
<!-- BRIEF: <verbatim operator brief from first turn> -->

# <Project> — REQUIREMENTS.md (v1)

## 0. Conventions
<terminology, ID schemes (CAP-XXX), abbreviations>

## 1. System Topology
<one paragraph: what the project is, who uses it, the deployment shape (single binary / service / container / etc.). OS + runtime versions pinned.>

## 2. Capabilities (v1)
- **CAP-001** — <one-paragraph capability>
- **CAP-002** — <...>

## 3. External Integrations
<one §3.N per integration: name, auth model, credential ownership, runtime location, rotation story, failure behaviour. If none: "(none)".>

## 4. Operator Install & First-Run Experience  ← MANDATORY
<step-by-step from clean OS to running service. Each step: command + what it does + what it produces + failure modes.>

## 5. Sources of Truth  ← MANDATORY
| Fact | Authoritative source | Read by | Written by |
|------|---------------------|---------|------------|
| <...> | <...> | <...> | <...> |

## 6. Inputs and Outputs
<I/O surfaces with format + constraints>

## 7. Data Layer (if applicable)
<schemas, tables, retention. "(none — stateless)" if no persistence.>

## 8. Non-functional Requirements
<performance, platforms, security posture, observability. Stack constraints if operator volunteered any.>

## 9. Out of Scope (v1)
<at least 3 things considered and cut>

## 10. License
<SPDX identifier; LICENSE file ships separately>

## 11. Phase Log
<!-- Optional in fresh mode (created lazily on first `/new-phase`). Required once any `/new-phase` has run. -->

Chronological record of phases added via `/new-phase`. Each phase keeps its verbatim brief and a delta summary. The capability/integration/install/data details land in §1–§10 in place; this section is the brief archive + diff trail.

### Phase 1 — <inferred or "original baseline">
<!-- BRIEF (Phase 1): <copy from the top-of-file `<!-- BRIEF: ... -->` if it exists, OR "(see top-of-file BRIEF marker)"> -->
Delta: original `/new-project` baseline; see §1–§10 for full surface.

### Phase 2 — <short title>
<!-- BRIEF (Phase 2): <verbatim operator brief for Phase 2> -->
Delta:
- Added CAP-2.001, CAP-2.002.
- New integration INT-XYZ (see §3.N).
- Install: added step 5 in §4.
- Sources of truth: 2 new rows in §5.
- Data: schema change to <table> in §7.
- Out-of-scope (Phase 2): <list>.
```

**TBDs** go inline as `<!-- TBD: <one-line reason> -->` markers. They also get listed in the approval-gate summary handed back to the operator (see §8 below).

The **mandatory** sections are §4 (install walkthrough) and §5 (sources of truth). Their absence is a release blocker per master CLAUDE.md §7. If they cannot be populated, stop the interview and surface the blocker — do not advance to DESIGN/PLAN.

**§11 Phase Log** is **mandatory once any `/new-phase` has run** — it's the brief archive that future `/new-phase` runs scan to infer the next phase number. Don't delete or rewrite past phase entries; append only.

---

## 8. Approval gate

After all sections are populated (or marked TBD), surface a single concise summary to the operator and pause.

**Fresh mode summary:**

```
REQUIREMENTS.md populated, N of 11 sections complete.
TBDs:
  - §<X>: <one-line reason>
  - §<Y>: <one-line reason>
Recommend: approve and resolve <blocking TBD> before DESIGN.md, OR revise specific sections.
```

Then ask: *"Approve REQUIREMENTS.md and proceed to DESIGN/PLAN? Or revise specific sections?"*

**New-phase mode summary:**

```
Phase N+1 captured in §11.
New capabilities: CAP-N+1.001, CAP-N+1.002, ...
Touched sections: §3 (new integration INT-XXX), §4 (added step 5), §5 (added 2 rows), §7 (schema change).
Untouched: §1, §2 pitch, §6, §8, §9, §10.
TBDs (new):
  - §<X>: <one-line reason>
Recommend: approve and proceed to DESIGN/PLAN deltas, OR revise specific sections.
```

Then ask: *"Approve Phase N+1 in REQUIREMENTS.md and proceed to DESIGN/PLAN updates? Or revise specific sections?"*

**Branching on the operator's answer (both modes):**

- On **approve** → author `docs/DESIGN.md` (or DESIGN deltas in new-phase mode — only if the phase changed lifecycles, sources of truth, or error contracts) and `docs/PLAN.md` (or a new `## Phase N+1` section appended in new-phase mode), per their playbooks (`design.md`, `plan.md`).
- On **revise** → re-enter interview mode for the named sections only; do not redo sections the operator didn't touch.
- On **silence / rejection** → stay where you are. Do not advance to DESIGN/PLAN authoring without explicit approval.

The approval gate is load-bearing. The whole point of running the interview as a distinct phase — rather than synthesizing requirements from a one-shot operator brief — is that the operator gets a chance to see the captured shape before any design or plan ossifies around it.
