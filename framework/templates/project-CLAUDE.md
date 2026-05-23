> Inherits from `~/.claude/CLAUDE.md` (master rules).

# {{PROJECT_NAME}}

{{PROJECT_SUMMARY}}

## Stack

- Language: {{LANGUAGE}} {{LANGUAGE_VERSION}}
- Package manager: {{PACKAGE_MANAGER}}
- Test framework: {{TEST_FRAMEWORK}}
- CI: GitHub Actions

## Commands

```bash
# Install / sync deps
{{INSTALL_COMMAND}}

# Lint
{{LINT_COMMAND}}

# Format check
{{FORMAT_CHECK_COMMAND}}

# Typecheck
{{TYPECHECK_COMMAND}}

# Tests
{{TEST_COMMAND}}

# Build / run locally
{{RUN_COMMAND}}
```

## Project-specific rules

- <Any conventions or constraints unique to this project — keep this list short. If it grows beyond 20 lines, the content probably belongs in master `CLAUDE.md` (generic) or in `docs/DESIGN.md` (project-specific design).>

## Canonical docs

- `docs/REQUIREMENTS.md` — what this project is, what it does, install walkthrough, source-of-truth declarations
- `docs/DESIGN.md` — lifecycles of external integrations, sequences, error contracts (REQUIRED if external integrations exist)
- `docs/PLAN.md` — PR-gated build plan
- `docs/LEARNINGS.md` — retrospectives (if any)

## Notes

- Keep this file under ~50 lines. Master rules cover the general patterns; this file is project-specific overrides only.
- Doc maintenance is mandatory in every PR (master CLAUDE.md §7) — no "doc fix in a follow-up PR" exceptions.
