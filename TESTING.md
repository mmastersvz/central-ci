# Testing Locally

Three tools cover different layers of confidence. Run them in this order — fastest feedback first.

## 1. Script testing (no tooling required)

Complex logic lives in `scripts/`. These can be run directly against any local git repo by injecting the environment variables the GitHub runner would normally provide.

### `next-version.sh`

```sh
# Plain vX.Y.Z tag (no service prefix)
GITHUB_OUTPUT=/tmp/out.txt \
GITHUB_STEP_SUMMARY=/tmp/summary.md \
GITHUB_RUN_NUMBER=1 \
  bash scripts/next-version.sh

# With a service prefix
GITHUB_OUTPUT=/tmp/out.txt \
GITHUB_STEP_SUMMARY=/tmp/summary.md \
GITHUB_RUN_NUMBER=1 \
  bash scripts/next-version.sh my-service

cat /tmp/out.txt
cat /tmp/summary.md
```

### `generate-changelog.sh`

```sh
# Between two tags
GITHUB_OUTPUT=/tmp/out.txt \
GITHUB_SERVER_URL=https://github.com \
GITHUB_REPOSITORY=mmastersvz/central-ci \
  bash scripts/generate-changelog.sh v0.0.1 v0.0.2

# From a tag to HEAD (typical release use case)
GITHUB_OUTPUT=/tmp/out.txt \
GITHUB_SERVER_URL=https://github.com \
GITHUB_REPOSITORY=mmastersvz/central-ci \
  bash scripts/generate-changelog.sh v0.0.1 HEAD

# All commits (no previous tag)
GITHUB_OUTPUT=/tmp/out.txt \
GITHUB_SERVER_URL=https://github.com \
GITHUB_REPOSITORY=mmastersvz/central-ci \
  bash scripts/generate-changelog.sh "" HEAD

cat /tmp/out.txt
```

---

## 2. `actionlint` — static analysis

Validates YAML structure, expression types, input/output references, and shell scripts (via `shellcheck`). Run this before every commit.

### Install

```sh
# macOS
brew install actionlint

# Linux
bash <(curl https://raw.githubusercontent.com/rhysd/actionlint/main/scripts/download-actionlint.bash)
```

### Run

```sh
# Lint everything
actionlint

# Lint a specific file
actionlint .github/workflows/release.yml
```

`actionlint` catches the majority of structural mistakes — missing inputs, invalid context references, wrong expression types — without running anything.

---

## 3. `act` — run workflows locally via Docker

[`act`](https://github.com/nektos/act) runs workflow files inside a Docker container that mimics the GitHub Actions runner. Use this to validate full action wiring before pushing.

### Install

```sh
# macOS
brew install act

# Linux
curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash
```

### Run

```sh
# List all available workflows and jobs
act --list

# Run a specific test workflow (workflow_dispatch trigger)
act workflow_dispatch -W .github/workflows/test-changelog.yml

# Run with a real GitHub token (needed for any gh CLI or git push steps)
act workflow_dispatch -W .github/workflows/test-changelog.yml \
  --secret GITHUB_TOKEN="$(gh auth token)"

# Run a specific job within a workflow
act workflow_dispatch -W .github/workflows/test-changelog.yml \
  --job test-script-logic
```

### Known limitations

| Feature                               | Supported |
| ------------------------------------- | --------- |
| Composite actions via `./actions/...` | Yes       |
| Scripts via `scripts/`                | Yes       |
| `workflow_dispatch`                   | Yes       |
| `pull_request` event simulation       | Partial   |
| `workflow_call` (reusable workflows)  | No        |
| OIDC / `id-token`                     | No        |
| Some `github.*` context fields        | Partial   |

For workflows that use `gh release create` or `git push`, pass a real `GITHUB_TOKEN` — `act` does not stub those out.

---

## Recommended workflow

```
edit scripts/        →  bash scripts/foo.sh        (immediate feedback, no Docker)
edit actions/ or     →  actionlint                 (catch YAML/expression issues)
  .github/workflows/
                     →  act workflow_dispatch \    (full wiring check before push)
                          -W .github/workflows/test-<action>.yml \
                          --secret GITHUB_TOKEN="$(gh auth token)"
```
