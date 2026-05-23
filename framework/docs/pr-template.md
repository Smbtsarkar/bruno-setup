# PR body template

Every PR the `reviewer` subagent opens must use this structure. Main agent verifies it before merging.

```markdown
## <PR title>

**PLAN.md PR ref:** §8 PR <N.M>
**Implements:** <REQUIREMENTS.md or FEATURES.md § ref>

### How to verify (operator-runs-this)

```bash
# Concrete command sequence an operator can paste on a clean VM to verify this PR works end-to-end.
# Not "run the tests" — that's the gate's job. This is the operator simulation.
```

### Acceptance criteria

- [ ] <copied verbatim from PLAN.md acceptance list>

### Build trace

<completed task trace from coder, verbatim>

### Test results

- lint: pass
- typecheck: pass
- tests: pass (coverage X%)

### Deviations / notes

<empty, or non-blocking notes>
```

The "How to verify (operator-runs-this)" section is **mandatory** — concrete pasteable commands, not "run the test suite". If the PR can't be verified by an operator, the PR is incomplete.
