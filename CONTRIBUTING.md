# Contributing Guide

## Pull Request workflow

All changes must go through a PR. The following checks run automatically:

| Check                   | Workflow | Runs on                                          |
| ----------------------- | -------- | ------------------------------------------------ |
| `actionlint`            | `ci.yml` | Every PR                                         |
| `prettier --check`      | `ci.yml` | Every PR                                         |
| `test-setup-git-config` | auto     | Every PR                                         |
| `test-next-version`     | auto     | Every PR                                         |
| `test-pr-version`       | auto     | Every PR                                         |
| `test-resolve-version`  | auto     | Every PR                                         |
| `test-changelog`        | auto     | Every PR                                         |
| `test-git-tag`          | manual   | `workflow_dispatch` only — creates real tags     |
| `test-gh-release`       | manual   | `workflow_dispatch` only — creates real releases |
| `test-move-major-tag`   | manual   | `workflow_dispatch` only — creates real tags     |

Run the manual tests via `gh workflow run <name>.yml` or the Actions tab before merging any change that touches `git-tag`, `gh-release`, or `move-major-tag`.

See [TESTING.md](TESTING.md) for local testing instructions.

---

## Composite Action vs. Reusable Workflow

When adding something new to this library, use the following rules to decide which pattern to reach for.

### Use a composite action (`/actions/<name>/action.yml`) when

- It is a **step-level building block** — something a job does, not something a job is
- Its outputs are consumed by **subsequent steps in the same job**
- It has **no permissions requirements** of its own (it inherits the caller's job permissions)
- It performs a **computation or setup**: installing a tool, computing a value, configuring git, etc.
- It produces **no durable side effects** that other jobs need to wait on

Examples from this library: `setup-git-config`, `next-version`, `pr-version`, `resolve-version`, `git-tag`

### Use a reusable workflow (`/.github/workflows/<name>.yml` with `workflow_call`) when

- It represents a **complete CI job** — build, test, lint, deploy, release
- It needs its own **`permissions:` block** to follow least privilege (e.g. `packages: write` for pushing to a registry, `id-token: write` for OIDC)
- It needs its own **`secrets:` declaration** rather than inheriting from a parent job
- It **produces artifacts or side effects** (a published image, a deployed service, a cut release) that downstream jobs consume via `needs:`
- It would otherwise be copy-pasted wholesale across multiple calling repositories

### The practical test

Ask: _"Is this a step inside a job, or is this a job?"_

- **Step inside a job** → composite action
- **A job (or a pipeline of jobs)** → reusable workflow

A reusable workflow that only computes a value and passes it out as an output is a signal you should be writing a composite action instead — you are paying for a full runner spin-up and `needs:` wiring for something that takes milliseconds.

### Calling composite actions from reusable workflows

The two patterns compose. A reusable workflow is the right home for a complete release pipeline, and it calls composite actions as its steps:

```yaml
jobs:
  release:
    runs-on: ubuntu-latest
    permissions:
      contents: write
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - uses: mmastersvz/central-ci/actions/setup-git-config@v1

      - uses: mmastersvz/central-ci/actions/resolve-version@v1
        id: version

      - uses: mmastersvz/central-ci/actions/git-tag@v1
        with:
          new-tag: ${{ steps.version.outputs.new-tag }}
          token: ${{ secrets.GITHUB_TOKEN }}
```
