# Testing patterns

Project conventions every Bruno-managed project ships with. Reviewer and senior-reviewer enforce these.

---

## Mocks must enforce contracts

Any mock of an external client must verify the **protocol contract** it replaces, not just the surface API.

- A mock of an SDK client must verify `connect()` was called before `query()`.
- A mock of an HTTP client must verify auth headers were set before requests.
- A mock of a database client must verify `commit()` was called after writes that require it.
- A mock of an OS subprocess must verify env vars were exported, not just `subprocess.run()` was called.

Without contract enforcement, tests pass on broken code — the test confirms the call shape, not that the call would actually work. The Citadel v1.0.9 `ClaudeSDKClient.connect()` bug is the canonical example: the mock returned a usable client object for `query()`, but the real SDK requires `connect()` first.

**Convention:** any new mock added in a PR must include a contract assertion. Reviewer checks for this; senior-reviewer treats mock-without-contract as LOOSE END.

---

## Integration tests don't skip by default

Test modes that default to `SKIP_X=1` flags hide the fragile paths from CI. Examples from Citadel: `TEMP_ROOT` mode defaulted `SKIP_UV_INSTALL=1`, `SKIP_APT=1`, `SKIP_SYSTEMD=1` — every install bug in v1.0.3–v1.0.7 lived in those skipped paths.

**Rule:** skip flags exist for **dev convenience only**. CI must run with all skips off. If a path is too expensive for every CI run (e.g. real `apt-get install`), put it behind a separate CI job that runs at minimum on every merge to dev — never default-skipped.

Reviewer checks the test fixture for skip-flag defaults; senior-reviewer treats a default-on skip flag as BLOCKER unless explicitly justified.
