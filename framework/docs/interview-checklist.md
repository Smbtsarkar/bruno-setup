# Pre-interview operator checklist

For the **operator** (the user, not the agent) to review **before** the requirements interview begins. Surfaces the prep work that — if missing — causes interview waste and downstream bugs.

If you can't answer most of these going into the interview, that's fine — note them as TBD, and we'll surface them as open questions in PLAN.md. But every TBD here is a known risk for an interview gap that produces a v1.0.x-class bug pile later.

---

## 1. Project name and scope

- [ ] **Project name.** A repo-able name (`my-project`, not "thing I want to build"). Will become `~/Projects/<name>`.
- [ ] **One-sentence pitch.** "This project is ___ that lets ___ do ___." If you can't say it in one sentence, the scope is too big.
- [ ] **Three things you explicitly considered and CUT from v1.** Forces you to articulate the boundary.

---

## 2. Deployment target — be exact

- [ ] **Operating system + version.** "Ubuntu 26.04 server", "macOS 14 desktop", "Debian 12 in Docker". Not "Linux". The OS version pins library compatibility and CI runner image.
- [ ] **Runtime + version.** Python 3.13? Node 22? Go 1.23? Pin exactly.
- [ ] **Container runtime (if any).** Docker? Podman? Kubernetes? None?
- [ ] **Will the install ever happen on a clean VM, or always on a maintained host?** Determines whether `setup.sh` needs to be fully bootstrapping or can assume curated state.

If this section is "I'm not sure, I'll figure it out", DESIGN.md cannot be written and install-gate cannot be configured. That's the Citadel-pattern install-bug substrate.

---

## 3. Operator persona

- [ ] **Who installs and operates this?** Just you? A small team? Distributed contributors? A fleet?
- [ ] **Are operators technical?** Can they read a stack trace? Can they edit a JSON config? Or do they need a wizard?
- [ ] **Single-tenant or multi-tenant?** One operator → one install? Or N operators sharing infrastructure?

The operator persona determines how `setup.sh` should be designed, how forgiving the env handling needs to be, and what "operator-runs-this" looks like at PR time.

---

## 4. External integrations — per integration

For **each** external system the project will integrate with (Discord, Slack, Google APIs, OAuth providers, payment APIs, MCP servers, third-party SDKs, third-party services in general):

- [ ] **Name and version pin.**
- [ ] **Auth model.** API key? OAuth (which flow?)? Subscription? Service account? Webhook secret?
- [ ] **Who supplies the credential?** Operator brings their own? Harness generates it during setup? Per-tenant provisioning?
- [ ] **Where does the credential live at runtime?** Env var? Config file? Secrets manager? Encrypted on disk?
- [ ] **What's the credential rotation story?** Manual rotation by operator? Automatic refresh via SDK? Indefinite?
- [ ] **What happens if the credential is missing or invalid?** Hard fail? Warn and degrade? Block specific features only?
- [ ] **What documentation does the operator need to set up the credential externally?** (Google Cloud Console steps, Discord Developer Portal steps, etc.) The harness can't generate API keys for the operator.

If any field is "I don't know yet" — that's an open question. **It must be resolved before DESIGN.md can include this integration**, because lifecycle and source-of-truth declarations depend on it.

Citadel v1.0.6 (Google OAuth dead-end) was 100% a "we didn't define who produces token.json" gap that this checklist would have caught.

---

## 5. Install path — walk it mentally

- [ ] **Step 1: operator opens a clean OS install. What's the first command they type?**
- [ ] **Step 2: …**
- [ ] **Step N: the service is running and the operator has used a feature.**

You don't have to write every step here — that's the interview's job. But you should have an outline. If you can't sketch even the first 5 steps, the install path is undefined.

This walkthrough becomes REQUIREMENTS.md §"Operator Install & First-Run Experience" — the spec for `setup.sh` + `README.md` + `preflight` together.

---

## 6. Upgrade path

- [ ] **How does an existing install upgrade to a new version?** In-place update? Blue/green? Manual `git pull` + restart? Tag-driven release pulled by the service itself?
- [ ] **Is there a rollback story?** What happens if v1.5 → v1.6 breaks?
- [ ] **Does upgrade involve schema migrations?** Who runs them?

If the upgrade path is "I'll figure that out later", PLAN.md can't include a Phase 7 (release + update) — or it will include one but it'll be wrong (cf. Citadel's `/update` originally pulling from `dev` instead of `master`).

---

## 7. Definition of "done" per phase

- [ ] **What does "Phase N is done" mean concretely?** Beyond "unit tests pass".
- [ ] **Will install-gate run end of each phase?** (Recommended yes — that's master CLAUDE.md §15 / deployment-gate.md.)
- [ ] **Will real-VM smoke happen at major-milestone phases?** (Recommended yes for Phase 3/5/7-class milestones.)

"Done = tests pass" is the trap. It's how v1.0.x shipped install bugs. "Done = install works on clean container" is the discipline.

---

## 8. Reference codebases (huge accelerator)

- [ ] **Is there an existing codebase to port from?** Even partial overlap (similar bot framework, similar deployment shape, similar config loader) is high-leverage. Cite the repo path; the planner will use it as the "Port from" pointer per PLAN.md template.

Citadel's 31-PR-in-one-day build was 90% because deepclaw existed as a port-from reference. Without it, the same work would have been 5-10× longer. If you have a reference, use it.

---

## 9. Anti-checklist — things that DON'T need to be answered

To keep the interview tight, you do NOT need to know in advance:

- Exact library versions (planner picks via `~/.claude/docs/plan.md` library-choice section).
- Exact file paths inside the project (those land in DESIGN.md's source-of-truth table during writing).
- Test framework choice (planner picks based on stack convention).
- CI provider (defaults to GitHub Actions unless you specify).

If you have opinions on these, share them; if not, the planner picks sensible defaults.

---

## Going in

Bring this checklist to the interview. Anything you couldn't fill in beforehand becomes the first round of interview questions — and that's fine, that's exactly what the interview is for.

What's NOT fine is starting the interview without having thought about this at all. That's how Citadel shipped a setup.sh that nobody had actually walked through.
