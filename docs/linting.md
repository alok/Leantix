# Linting & Error-Message Infrastructure

> **Status:** Foundation ready (2025-06-11).  To be expanded with real rules once
> the code base grows.

This folder documents how linting is wired into the Golitex repo and how we plan
to leverage Lean 4’s **extensible error-message** machinery (see upstream commits
[`lean4@master`](https://github.com/leanprover/lean4/commits/master)) for rich
developer feedback.

## 1. Quickstart

• Run `lake exe golitex-lint` for a fast all-in-one lint check (currently a
  stub; will evolve).  
• `pre-commit` is configured so that every commit formats and lints .lean files
  automatically.

## 2. Lean-level linter (`golitex-lint`)

Located at `Scripts/GolitexLintMain.lean`, compiled into an executable via Lake.

Planned rules (future work):

1. Missing doc-strings on `def` / `inductive` (severity: warning).
2. Unused namespace openings.
3. Forbidden `unsafe` usage except in whitelisted modules.
4. Lean syntax quoting anti-pattern detection (e.g. `ident` instead of
   `quotedName`).

The Lean 4 core provides an **extensible message category** API (`Lean.registerMessageCategory`)
and **diagnostic** helpers.  Each rule will register its own category so that
IDE clients can filter & colour them individually.

## 3. Git hooks

The `.pre-commit-config.yaml` file installs three hooks:

1. **lean-fmt** – Formats staged `.lean` files via `lake fmt`.
2. **lean-build** – Compiles the project (`lake build`).
3. **golitex-lint** – Runs the Lean linter described above (optional for now).

To set up locally:

```bash
pipx install pre-commit   # or pip install pre-commit
pre-commit install
# optionally run on all files once:
pre-commit run --all-files
```

## 4. CI integration

When CI is added (GitHub Actions + bors), we will run the same three steps in a
dedicated job so that the gate never lets bad code through.

---

*(End of file)*
