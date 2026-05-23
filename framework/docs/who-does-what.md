# Who does what — quick reference

Lookup table for which actor owns each step in Bruno's pipeline.

| Action                                            | Owner                                                       |
| ------------------------------------------------- | ----------------------------------------------------------- |
| Gather requirements from the operator             | Main agent (brief-first turn-by-turn interview, `requirements.md` playbook) |
| Explore an unfamiliar codebase                    | System `Explore` agent (capital E)                          |
| Write `docs/REQUIREMENTS.md`                      | Main agent (incremental, section by section)                |
| Approve `docs/REQUIREMENTS.md`                    | Operator (gate before DESIGN/PLAN authoring)                |
| Write `docs/DESIGN.md`                            | Main agent (`design.md`, after operator approves REQUIREMENTS) |
| Write `docs/PLAN.md`                              | Main agent (`plan.md`, after operator approves REQUIREMENTS) |
| Scaffold a new project from a stack template      | `scaffolder`                                                |
| Extract PR brief from PLAN.md                     | Main agent                                                  |
| Decide which files a PR touches                   | Main agent (from PLAN.md)                                   |
| Write production code or unit tests               | `coder`                                                     |
| Update dependency / lockfile                      | `coder`                                                     |
| Write integration tests + CI workflow             | `coder`                                                     |
| Author Bruno API collection (backend)             | `coder`                                                     |
| Relay coder's `summary_for_operator`              | Main agent (sync gate, see `pipeline.md`)                   |
| Drive the artifact end-to-end before PR           | `reviewer` (comprehensive mode)                             |
| Run Bruno API collection (backend)                | `reviewer` (during e2e exercise)                            |
| Run lint / typecheck / unit tests                 | `reviewer`                                                  |
| Scan for adjacent surfaces with same root cause   | `reviewer` (comprehensive mode, mandatory)                  |
| Run security audit                                | `reviewer`                                                  |
| Diagnose a stack trace / failing test             | `debugger` (auto-invoked on operator-reported errors)       |
| Fetch and parse log files                         | `debugger`                                                  |
| Write `README` / `CHANGELOG` / `ARCHITECTURE`     | `docs` (or main agent for docs-only PRs)                    |
| Flag doc-vs-code drift                            | `docs` (`drift_found` mandatory field)                      |
| Open the PR (`gh pr create`)                      | `reviewer`                                                  |
| Pre-merge scope check (`git diff --stat`)         | Main agent                                                  |
| Pre-merge doc-drift check                         | Main agent (extended scope check)                           |
| Squash-merge (`gh pr merge`)                      | Main agent                                                  |
| Release-readiness review + install-walkthrough    | `senior-reviewer` (auto-invoked before release-PR approval) |
| Adjudicate DESIGN / REQUIREMENTS / PLAN conflicts | Main agent → escalate to operator                           |
| Classify reviewer deviations as blocking / nit    | Main agent                                                  |
| Decide PR scope                                   | Nobody — PLAN.md is fixed                                   |
