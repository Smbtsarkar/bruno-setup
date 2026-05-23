# Operator install walkthrough

How Bruno-managed projects document and validate the operator's first install.

---

## REQUIREMENTS.md must include an Install & First-Run Experience section

Every project's REQUIREMENTS.md must include an **"Install & First-Run Experience"** section — step-by-step from clean OS through running service. Every credential the operator produces, every config file the operator edits, every command the operator types. This is the spec for `setup.sh` + `README.md` + `preflight` together.

If this section doesn't exist, the operator install path is undefined — and that's how projects ship initial releases with install bugs the operator hits the first time they try.

Senior-reviewer's install-walkthrough check validates this section against the actual install on a clean container.

---

## First-install batching contract

When the operator is doing a **first install** or a **major upgrade** that may surface multiple issues:

- **Do NOT release between findings.** Each hotfix release has overhead (senior-reviewer pass, CI runs, tag push, release.yml strip+publish, context rebuild for the next brief).
- **Collect every failure into one batch.** Operator runs the install to completion, logs every failure into a notebook, hands the full list to main agent.
- **Fix as ONE consolidated PR.** Bundle every issue from the batch into a single PR titled something like `fix: <version> release blockers`. One release per batch.

Why: serialised hotfixes (1 bug → 1 fix → 1 release → operator hits next bug → repeat) cost 5–10× the time of a batched fix and prevent class-level analysis. Batching forces the bug pile into view at once, which enables class-level fixes.
