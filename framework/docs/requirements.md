# Requirements interview playbook

Main agent uses this when conducting a requirements interview at `/new-project` or when an existing project's REQUIREMENTS.md is missing/stale.

The output is a populated `docs/REQUIREMENTS.md` in the project root.

---

## 0. Before you start the interview

Confirm the operator has reviewed `~/.claude/docs/interview-checklist.md` (operator-side prep). If they haven't, ask them to skim it first. Reasons:

- Two of the historically expensive mistakes (missing deployment-target spec, missing credential-ownership spec) come from interview gaps where the operator didn't have the answer ready.
- The pre-interview checklist surfaces those gaps before you waste cycles asking and getting "I don't know" twice (which is an escalation trigger per escalation.md).

If the operator is ready, proceed.

---

## 1. Interview script

Ask these in order. Don't proceed to the next section until the current section has concrete answers (or an explicit TBD with a follow-up plan).

### 1.1 What and why

- **One-sentence pitch.** "This project is ___ that lets ___ do ___."
- **Who is the operator?** Single user? Small team? Distributed contributors? Hands-on or hands-off?
- **What's the deployment target?** Be exact. "Ubuntu 26.04 server", "macOS desktop", "AWS Lambda", "browser extension". Pin the OS version, the runtime version, the container runtime if any.
- **What's NOT in scope for v1?** Operator should be able to list at least 3 things they considered and explicitly cut.

### 1.2 External integrations

For every external system the project will integrate with (Discord, Slack, Google APIs, OAuth providers, MCP servers, payment APIs, etc.), capture:

- **Name and version pin.**
- **Auth model.** API key? OAuth? Subscription? Service account?
- **Who supplies the credential?** Operator brings it? Harness generates it? Per-deployment?
- **How does the credential reach the running process?** Env var? Config file? Secrets manager?
- **What's the credential rotation story?** Manual rotation? Automatic refresh? Indefinite?
- **What happens if the credential is missing or invalid?** Hard fail? Warn and degrade? Block specific features only?

If any integration's answer is "I don't know yet" — that's an open question, log it. **Do not proceed to design with unresolved integration questions.** They surface as bugs in production (cf. Citadel v1.0.6 Google OAuth dead-end).

### 1.3 Operator install walkthrough (MANDATORY)

Walk the operator through their imagined first install, **end to end, keystroke by keystroke**:

```
Operator opens a fresh OS install. What's the FIRST command they type?
(...continue until the service is running and the operator has used a feature.)
```

For each step, capture:
- **Command** (exactly what the operator types).
- **What it does** (one line).
- **What it produces** (file? service? config?).
- **Failure modes** (what happens if this step fails? recoverable?).

This walkthrough becomes the REQUIREMENTS.md §"Install & First-Run Experience" section. It is **the spec for `setup.sh` + `README.md` + `preflight` together**.

If the operator can't walk this without going "I'll figure that out later" more than once, that's a red flag — the install path is undefined, and the project will ship with operator-discovered install bugs (cf. Citadel v1.0.3–v1.0.7).

### 1.4 Source-of-truth declarations

For every fact the project will need to know — file paths, env var names, schema fields, channel IDs, credential locations, allowlists — explicitly capture **which file is authoritative**.

Example template:

| Fact | Authoritative source | Read by | Written by |
|------|---------------------|---------|------------|
| Backup destination path | `config.toml:[backup].path` | `backup.drive.upload()` | Operator (manual edit) |
| Discord bot tokens | `/etc/citadel/citadel.env:DISCORD_TOKEN_*` | systemd EnvironmentFile + `discord_bot.app:load_*` | Operator (manual edit) |
| age public key | `/etc/citadel/citadel.env:BACKUP_AGE_RECIPIENT` (auto-populated from `age-identity.txt`) | `backup.age:encrypt()` | `setup.sh` Step 8.5 |

This table goes into REQUIREMENTS.md §"Sources of truth" and is mirrored in DESIGN.md §"Sources of truth" (same data, different audience). When two components disagree on a fact, this table is the tie-breaker — and the disagreement itself is the bug to fix.

Missing this table is how Citadel shipped v1.0.5 (loader looked at `/etc/citadel/.env`, setup.sh wrote `/etc/citadel/citadel.env`, neither component knew the other existed).

### 1.5 Functional and non-functional requirements

- **Capabilities (v1).** Enumerated list of what the software does, one bullet per capability. Each capability gets a unique ID (CAP-001, CAP-002, …) for traceability.
- **Inputs.** What the software ingests (file types, network protocols, user input shapes).
- **Outputs.** What the software produces (files, network responses, UI, side effects).
- **Performance.** Throughput, latency, memory, disk targets.
- **Platforms.** OS, runtime, dependencies.
- **License.** SPDX identifier (e.g. MIT, Apache-2.0).

### 1.6 Definition of "done"

For each phase in the plan (which you'll write next per `~/.claude/docs/plan.md`), define what "done" means **concretely**:

- ✅ Unit tests pass
- ✅ Integration tests pass
- ✅ **Install-gate passes on a clean container** (cf. master CLAUDE.md §15 / deployment-gate.md)
- ✅ README documents the new capability
- ✅ DESIGN.md updated if the phase added a lifecycle or external integration

"Done" without an install-gate check is "not done" — that's the Citadel v1.0.x lesson.

---

## 2. REQUIREMENTS.md output template

Write the populated REQUIREMENTS.md to `docs/REQUIREMENTS.md` with this section structure:

```markdown
# <Project> — REQUIREMENTS.md (v1)

## 0. Conventions
<terminology, ID schemes, abbreviations>

## 1. System Topology
<single-process vs distributed, filesystem layout, services, deployment unit>

## 2. Capabilities (v1)
<numbered CAP-XXX list with one-paragraph each>

## 3. External Integrations
<one §3.N per integration: auth model, credential flow, failure modes>

## 4. Operator Install & First-Run Experience  ← MANDATORY, from §1.3 walkthrough
<step-by-step from clean OS to running service>

## 5. Sources of Truth
<the table from §1.4>

## 6. Inputs and Outputs
<I/O surfaces>

## 7. Data Layer (if applicable)
<schemas, tables, retention>

## 8. Non-functional Requirements
<performance, platforms, security posture, observability>

## 9. Out of Scope (v1)
<what was considered and cut>

## 10. License
<SPDX identifier, full LICENSE file ships separately>
```

Adjust section numbering as needed; the **mandatory** sections are §4 (install walkthrough) and §5 (sources of truth). Their absence is a release blocker per master CLAUDE.md §7.

---

## 3. After the interview

1. Write `docs/REQUIREMENTS.md` per the template.
2. **If any external integrations were declared in §1.2**, immediately proceed to write `docs/DESIGN.md` per `~/.claude/docs/design.md`. DESIGN.md is REQUIRED for projects with external integrations.
3. Then write `docs/PLAN.md` per `~/.claude/docs/plan.md`.
4. Surface all three docs to the operator for approval before any scaffolding.

If the operator approves with TBDs in any section, log the TBDs as `open_questions` in PLAN.md's first PR. Don't proceed past the PR that needs the answer without resolving it.
