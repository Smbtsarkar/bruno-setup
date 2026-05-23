# DESIGN.md playbook

Main agent uses this when writing `docs/DESIGN.md` for a project. DESIGN.md is the **missing layer** between REQUIREMENTS (what) and PLAN (PR-by-PR work) — it captures the design decisions that aren't in code yet but constrain how code gets written.

**DESIGN.md is REQUIRED if the project integrates any external system** (Discord, Slack, OAuth provider, MCP server, third-party SDK, message queue, database with non-trivial schema). Recommended otherwise.

Without DESIGN.md, lifecycle bugs (init-before-use, connect-before-query, env-loaded-where), source-of-truth conflicts, and error-recovery omissions all surface in production. The Citadel v1.0.2, v1.0.5, v1.0.6, and v1.0.9 bug classes were all DESIGN.md-shaped gaps.

---

## 1. DESIGN.md structure

```markdown
# <Project> — DESIGN.md (v1)

## 0. Scope
<one paragraph: what this doc covers vs what REQUIREMENTS covers vs what PLAN covers>

## 1. Sources of Truth
<the canonical answer for every fact — same table as REQUIREMENTS §5, repeated here for code-author audience>

## 2. Lifecycles
<one §2.N per external integration: when initialized, when used, when torn down, who manages>

## 3. Sequences
<one §3.N per load-bearing flow: text-sequence diagrams of who calls what in what order>

## 4. Error and Recovery Contracts
<one §4.N per failure mode: what fails, what state it leaves, what recovery looks like>

## 5. First-Install vs Re-Install
<what state is operator-provided, what is harness-produced, what is first-run-only>

## 6. Configuration Loading and Precedence
<config file vs env var vs CLI flag — what wins, why, in what order>
```

---

## 2. Section-by-section: what goes in each

### §1 Sources of Truth

Copy the table from REQUIREMENTS.md §5. Repeat it here for the code-author audience (who reads DESIGN, not REQUIREMENTS).

When a coder is implementing component X that touches fact Y, they should be able to look at this table and know: "the authoritative source is Z; I read from Z; if I need to write Y, only the documented writer-component does that."

This single section, taken seriously, prevents the v1.0.5/v1.0.9 class of bug (two sources of truth, neither wins).

### §2 Lifecycles

For every external integration declared in REQUIREMENTS §3, document:

```markdown
### 2.N <Integration name>

**Library:** `<sdk>` version `<pin>`

**Initialization:**
- When: <which startup phase, which CLI command, which trigger>
- Where: <module that owns the init>
- What state must exist beforehand: <pre-init invariants>

**Use:**
- Method(s) called: <`client.query()`, `client.stream()`, etc.>
- Required before-call state: **`<protocol contract — e.g. "connect() must have been awaited">`** ← critical
- Reentrance: <can multiple calls overlap? must be serialized?>

**Teardown:**
- When: <on shutdown, on session-end, on idle timeout>
- Where: <module that owns the teardown>
- Cleanup invariants: <what must be true after teardown>

**Failure modes:**
- Init fails: <what error, what recovery>
- Use fails mid-call: <retry policy, fallback>
- Teardown fails: <log and continue, or hard-fail>
```

**The "Required before-call state" line is the single most important field**, because that's exactly what mocks must enforce per master CLAUDE.md §21. The Citadel v1.0.9 bug was: ClaudeSDKClient required `connect()` before `query()`; the lifecycle wasn't documented; the mock didn't enforce it; tests passed; production crashed.

If you can't fill this section for an integration, **you don't yet understand the integration well enough to write code that uses it.** Stop and learn.

### §3 Sequences

For every load-bearing flow, document the call sequence in text. Pick the flows that matter for correctness — not every flow.

Examples of flows that always matter:
- **Process startup**: from systemd/launcher → init → first response handled.
- **Primary request handling**: from input event → routing → processing → output.
- **Update/upgrade**: from trigger → fetch → apply → restart → verify → rollback.
- **Restore from backup**: from CLI invocation → decrypt → unpack → DB restore → service start.
- **First-time setup**: from clean OS → operator commands → running service.

Template:

```markdown
### 3.N <Flow name>

**Trigger:** <what initiates this — operator command, schedule, network event>

**Sequence:**
1. <Component A> receives <trigger>
2. <Component A> validates <preconditions>
3. <Component A> calls <Component B>.method(args)
4. <Component B> ... (continue)
N. <Final component> emits <output> to <destination>

**Critical ordering invariants:**
- <X must happen before Y because Z>
- <A and B must not interleave because reason>

**Failure points:**
- Between step K and K+1: if <failure>, then <recovery>.
```

Text-sequence format is fine. PlantUML / mermaid are nice but not required. The discipline matters more than the rendering.

### §4 Error and Recovery Contracts

For every failure mode that the running system might encounter, document the contract:

```markdown
### 4.N <Failure name>

**What fails:** <component / call / network / disk>
**Symptom:** <what the operator/log sees>
**State on failure:** <what's left in a half-state — files, DB rows, in-memory state>
**Recovery:**
- Automatic: <retry policy, circuit breaker, fallback path>
- Operator-driven: <what the operator does — command, manual cleanup>
**Logged as:** <alert category, log level, where it surfaces>
```

Examples of failure modes that always need contracts:
- External API down (auth, primary integration, observability backend).
- Disk full / permission denied on write.
- Database lock contention / transaction conflict.
- Network partition mid-flow.
- Stale auth token detected mid-call.

If a failure mode has no documented contract, the implementation will do something arbitrary (often "raise and crash"). Document the intended behaviour so reviewer can verify code matches.

### §5 First-Install vs Re-Install

This is the single most error-prone section in the operator experience. Document explicitly:

```markdown
| State | First-install (operator-provided) | Harness-produced | First-run only |
|-------|-----------------------------------|------------------|----------------|
| `/etc/<project>/config.toml` | ✅ (operator edits) | seeded from example | — |
| `/etc/<project>/<project>.env` | ✅ (operator edits) | seeded with empty template | — |
| `/etc/<project>/age-identity.txt` | — | ✅ (setup.sh generates) | ✅ (regen would orphan past backups) |
| `/var/lib/<project>/state.db` | — | ✅ (alembic upgrade) | — |
| `/home/<user>/.local/bin/<bin>` | — | ✅ (installer) | — |
```

For each row, the four-way classification matters:
- Operator-provided: must exist before service can start; operator must produce.
- Harness-produced (re-run safe): setup.sh regenerates idempotently; operator can rm and re-run.
- First-run only: never regenerate after initial production (e.g. encryption keys — regen would orphan past data).
- Mixed (e.g. config.toml: operator edits after seeding): seed once, then operator owns it.

Citadel v1.0.6 (Google OAuth flow missing) was a first-install-vs-re-install ambiguity: nobody specified who produced `token.json` or when.

### §6 Configuration Loading and Precedence

If the project loads config from multiple sources (file + env + CLI flag), document the precedence explicitly:

```markdown
**Precedence (highest to lowest):**
1. CLI flag (e.g. `--key /path/to/key`)
2. Env var (e.g. `CITADEL_KEY_PATH`)
3. Config file field (e.g. `[backup].key_path` in `/etc/citadel/config.toml`)
4. Hardcoded default (e.g. `/etc/citadel/age-identity.txt`)

**Loading order:**
- Process start: env vars from `EnvironmentFile=` (systemd) — populates `os.environ` before Python imports any module.
- CLI startup: root callback runs `dotenv.load_dotenv(path, override=False)` — adds missing env vars from the file, does NOT overwrite what systemd already set.
- Per-component: each module reads `os.environ.get(...)` directly when needed.
```

The Citadel v1.0.5 bug was: the loader looked at `/etc/citadel/.env`, setup.sh wrote `/etc/citadel/citadel.env`, the precedence-and-loading section didn't exist, no component owned reconciling them.

---

## 3. When to update DESIGN.md

Update DESIGN.md (in the same PR as the code change) when:

- An external integration is added, removed, or replaced.
- A lifecycle step changes (e.g. teardown moves from end-of-session to idle-timeout).
- A sequence changes (e.g. preflight now runs before bot-connect instead of after).
- A source-of-truth declaration changes.
- A new failure mode is identified.
- The first-install vs re-install matrix changes.
- The configuration precedence changes.

Master CLAUDE.md §17 enforces this — any code change that touches a DESIGN.md fact must update DESIGN.md in the same commit, no follow-up-PR exceptions.

---

## 4. Anti-patterns

What DESIGN.md is **not**:

- ❌ A re-statement of REQUIREMENTS (REQUIREMENTS owns "what"; DESIGN owns "how, structurally").
- ❌ An architecture astronaut document (no UML diagrams of imaginary future microservices).
- ❌ A code dump (no full function bodies; cite file paths instead).
- ❌ A wishlist (only design decisions that have been made and are being implemented).
- ❌ A frozen artifact (it's living; updates land in every PR that changes a documented fact).

When in doubt: would a coder reading this doc be able to implement a new module that integrates with the system without breaking lifecycle/sequence invariants? If yes, DESIGN.md is doing its job.
