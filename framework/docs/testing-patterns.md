# Testing patterns

Project conventions every Bruno-managed project ships with. Reviewer and senior-reviewer enforce these.

---

## Mocks must enforce contracts

Any mock of an external client must verify the **protocol contract** it replaces, not just the surface API.

- A mock of an SDK client must verify `connect()` was called before `query()`.
- A mock of an HTTP client must verify auth headers were set before requests.
- A mock of a database client must verify `commit()` was called after writes that require it.
- A mock of an OS subprocess must verify env vars were exported, not just `subprocess.run()` was called.

Without contract enforcement, tests pass on broken code — the test confirms the call shape, not that the call would actually work. Canonical example: a mock SDK client that returns a usable object for `query()` even though the real SDK requires `connect()` first. Tests pass green; production crashes on first call.

**Convention:** any new mock added in a PR must include a contract assertion. Reviewer checks for this; senior-reviewer treats mock-without-contract as LOOSE END.

---

## Integration tests don't skip by default

Test modes that default to `SKIP_X=1` flags hide the fragile paths from CI. Typical pattern: a `TEMP_ROOT` (or similar) mode that defaults `SKIP_INSTALL=1`, `SKIP_APT=1`, `SKIP_SYSTEMD=1` — every install bug then lives in those skipped paths, undetected until production.

**Rule:** skip flags exist for **dev convenience only**. CI must run with all skips off. If a path is too expensive for every CI run (e.g. real `apt-get install`), put it behind a separate CI job that runs at minimum on every merge to dev — never default-skipped.

Reviewer checks the test fixture for skip-flag defaults; senior-reviewer treats a default-on skip flag as BLOCKER unless explicitly justified.
