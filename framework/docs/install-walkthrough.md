# Operator install walkthrough

How Bruno-managed projects document and validate the operator's first install. Derived from the Citadel v1.0.0–v1.0.8 release cycle.

---

## REQUIREMENTS.md must include an Install & First-Run Experience section

Every project's REQUIREMENTS.md must include an **"Install & First-Run Experience"** section — step-by-step from clean OS through running service. Every credential the operator produces, every config file the operator edits, every command the operator types. This is the spec for `setup.sh` + `README.md` + `preflight` together.

If this section doesn't exist, the operator install path is undefined. That's how Citadel shipped v1.0.0 without anyone walking through the install — and how v1.0.3 through v1.0.7 happened.

Senior-reviewer's install-walkthrough check validates this section against the actual install on a clean container.

---

## First-install batching contract

When the operator is doing a **first install** or a **major upgrade** that may surface multiple issues:

- **Do NOT release between findings.** Each hotfix release has overhead (senior-reviewer pass, CI runs, tag push, release.yml strip+publish, context rebuild for the next brief).
- **Collect every failure into one batch.** Operator runs the install to completion, logs every failure into a notebook, hands the full list to main agent.
- **Fix as ONE consolidated PR**, the same shape as the `[fix] v1.0.0 release blockers` PR in the Citadel build (bundled 5 distinct issues into one PR). One release per batch.

Why: serialised hotfixes (1 bug → 1 fix → 1 release → operator hits next bug → repeat) cost 5–10× the time of a batched fix and prevent class-level analysis. Batching forces the bug pile into view at once, which enables class-level fixes.
