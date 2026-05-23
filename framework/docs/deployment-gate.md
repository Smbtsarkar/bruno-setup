# Per-phase deployment gate

End of each PLAN.md phase = **working install on a clean container/VM**, not just unit tests green.

---

## The pattern

- **Per-PR (cheap):** Run an install-gate Docker container in CI that exercises the project's actual install path (e.g. `setup.sh`, `pip install`, `npm install` + post-install steps). Asserts the install completes and the binary/service comes up.
- **Per major-milestone phase (Phase 3, 5, 7 typically):** Smoke-test on a real VM with the documented install flow from `README.md`. If the install doesn't work end-to-end, the phase isn't done.

The install-gate is part of the per-project `.github/workflows/ci.yml` and `release.yml`. The release.yml gate runs install-gate as a prerequisite (`needs: install-gate`) so the strip+publish step can't fire if the install is broken.

---

## Why this matters

Integration tests that run inside the test runner don't model the operator's environment. Fragile paths (sudo CWD inheritance, real apt-get, real systemd, real OAuth flows) only fail in production. Install-gate moves discovery to CI.
