# central-ci

A library of reusable GitHub Actions composite actions and workflows.

## Versioning

This repo uses a single version for all actions. Pin to a major version tag (e.g. `@v1`) to receive patch and minor updates automatically. A new major version is only cut for breaking input or output changes.

```yaml
# Recommended — receives non-breaking updates automatically
uses: mmastersvz/central-ci/actions/resolve-version@v1

# Pinned — use when you need a specific fix or need to audit changes
uses: mmastersvz/central-ci/actions/resolve-version@v1.2.3
```

## Actions

### `setup-git-config`

Configures Git `user.name` and `user.email` globally on the runner.

**Usage:**

```yaml
- uses: mmastersvz/central-ci/actions/setup-git-config@v1
```

**With custom values:**

```yaml
- uses: mmastersvz/central-ci/actions/setup-git-config@v1
  with:
    git-user-name: "my-bot"
    git-user-email: "my-bot@example.com"
```

**Inputs:**

| Name | Description | Required | Default |
|---|---|---|---|
| `git-user-name` | Value for `git config user.name` | No | `github-actions[bot]` |
| `git-user-email` | Value for `git config user.email` | No | `github-actions[bot]@users.noreply.github.com` |

### `git-tag`

Creates and pushes a Git tag to origin. Requires the calling job to have `contents: write` permission.

**Usage:**

```yaml
- uses: mmastersvz/central-ci/actions/git-tag@v1
  with:
    new-tag: "v1.2.3"
    token: ${{ secrets.GITHUB_TOKEN }}
```

**Inputs:**

| Name | Description | Required | Default |
| --- | --- | --- | --- |
| `new-tag` | Tag name to create and push (e.g. `v1.2.3`) | Yes | — |
| `token` | GitHub token with `contents:write` permission | Yes | — |

### `resolve-version`

Auto-selects `next-version` for release builds or `pr-version` for pull request builds and exposes a single unified output contract. This is the recommended entry point for workflows that need version info.

**Usage:**

```yaml
- uses: mmastersvz/central-ci/actions/resolve-version@v1
  id: version

- run: echo "Tag is ${{ steps.version.outputs.new-tag }}"
```

**Force PR versioning (e.g. on `workflow_dispatch` with a PR number):**

```yaml
- uses: mmastersvz/central-ci/actions/resolve-version@v1
  id: version
  with:
    pr-number: ${{ github.event.inputs.pr-number }}
```

**Inputs:**

| Name | Description | Required | Default |
| --- | --- | --- | --- |
| `service` | Service name for tag prefixing, passed to `next-version`. | No | `""` |
| `token` | GitHub token for `git fetch`, passed to `next-version`. | No | `github.token` |
| `pr-number` | Forces PR versioning when provided, regardless of event type. | No | `""` |

**Outputs (shared contract with both `next-version` and `pr-version`):**

| Name | Release example | PR example |
| --- | --- | --- |
| `new-tag` | `v1.2.3` | `0.0.0-pr.123.5.1` |
| `marketing-version` | `1.2.3` | `0.0.0-pr.123.5.1` |
| `previous-tag` | `v1.2.2` | `""` |
| `release-type` | `minor` | `prerelease` |
| `is-prerelease` | `false` | `true` |

---

### `changelog`

Generates a Conventional Commits grouped changelog between two tags. Output is markdown suitable for passing directly to `gh-release`.

**Usage:**

```yaml
- uses: mmastersvz/central-ci/actions/changelog@v1
  id: changelog
  with:
    previous-tag: ${{ steps.version.outputs.previous-tag }}
    new-tag: ${{ steps.version.outputs.new-tag }}
```

**Inputs:**

| Name | Description | Required | Default |
| --- | --- | --- | --- |
| `previous-tag` | Tag to diff from. Includes all commits if empty. | No | `""` |
| `new-tag` | Tag to diff to. | No | `HEAD` |

**Outputs:**

| Name | Description |
| --- | --- |
| `notes` | Grouped changelog markdown |

**Output format:**

```markdown
## Breaking Changes
- feat!: remove legacy auth endpoint (`a1b2c3d`)

## Features
- feat: add service prefix support to next-version (`e4f5g6h`)

## Bug Fixes
- fix: correct GITHUB_RUN_NUMBER usage in shell scripts (`i7j8k9l`)

## Other Changes
- chore: update actionlint config (`m1n2o3p`)

**Full Changelog**: https://github.com/org/repo/compare/v1.0.0...v1.1.0
```

---

### `gh-release`

Creates a GitHub release for an existing git tag.

**Usage:**

```yaml
- uses: mmastersvz/central-ci/actions/gh-release@v1
  with:
    tag: ${{ steps.version.outputs.new-tag }}
    title: ${{ steps.version.outputs.marketing-version }}
    token: ${{ secrets.GITHUB_TOKEN }}
```

**Inputs:**

| Name | Description | Required | Default |
| --- | --- | --- | --- |
| `tag` | Existing git tag to release | Yes | — |
| `title` | Release title. Falls back to `tag` if omitted. | No | `""` |
| `token` | GitHub token with `contents:write` permission | Yes | — |
| `notes` | Release notes markdown. When provided, `generate-notes` is ignored. | No | `""` |
| `generate-notes` | Auto-generate release notes from merged PRs. Ignored when `notes` is set. | No | `"true"` |
| `release-type` | Bump type for step summary display only | No | `""` |
| `previous-tag` | Previous tag for step summary display only | No | `""` |

---

### `next-version`

Computes the next semver tag from [Conventional Commits](https://www.conventionalcommits.org/). Supports an optional service prefix or plain `vX.Y.Z` tags.

| Commit pattern | Bump |
| --- | --- |
| `feat!:`, `fix!:`, `BREAKING CHANGE` | major |
| `feat:` | minor |
| anything else | patch |

**Usage (plain tags):**

```yaml
- uses: mmastersvz/central-ci/actions/next-version@v1
  id: version
# outputs: v1.2.3
```

**Usage (service prefix):**

```yaml
- uses: mmastersvz/central-ci/actions/next-version@v1
  id: version
  with:
    service: "my-service"
# outputs: my-service/v1.2.3
```

**Inputs:**

| Name | Description | Required | Default |
| --- | --- | --- | --- |
| `service` | Service name used as tag prefix. Omit for plain `vX.Y.Z`. | No | `""` |
| `token` | GitHub token for `git fetch` on private repos. | No | `github.token` |

**Outputs:**

| Name | Description |
| --- | --- |
| `new-tag` | The next computed tag (e.g. `v1.2.3` or `my-service/v1.2.3`) |
| `previous-tag` | The most recent matching tag, or empty string if none exists |
| `release-type` | The bump type applied: `major`, `minor`, or `patch` |
| `marketing-version` | The bare version number without prefix or `v` (e.g. `1.2.3`) |

### `pr-version`

Computes a pre-release version string for pull request builds. Outputs a SemVer-compatible pre-release version and a dot-separated build identifier.

| Output | Example |
| --- | --- |
| `version` | `0.0.0-pr.123.5.1` |
| `build-id` | `123.5.1` |

**Usage (automatic — no inputs needed in a PR context):**

```yaml
- uses: mmastersvz/central-ci/actions/pr-version@v1
  id: version
```

**Usage (explicit inputs):**

```yaml
- uses: mmastersvz/central-ci/actions/pr-version@v1
  id: version
  with:
    pr-number: ${{ github.event.pull_request.number }}
    run-number: ${{ github.run_number }}
    run-attempt: ${{ github.run_attempt }}
```

**Inputs:**

| Name | Description | Required | Default |
| --- | --- | --- | --- |
| `pr-number` | PR number. Auto-detected from event context when omitted. | No | `""` |

**Outputs:**

| Name | Description |
| --- | --- |
| `new-tag` | Pre-release version string (e.g. `0.0.0-pr.123.5.1`) |
| `marketing-version` | Same as `new-tag` for PR builds |
| `previous-tag` | Always empty for PR builds |
| `release-type` | Always `prerelease` |
| `build-id` | Dot-separated build identifier (e.g. `123.5.1`) |

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for architectural guidelines, including when to write a composite action vs. a reusable workflow.

## Testing

Test workflows live in `.github/workflows/` and are prefixed with `test-`.

To run them:

1. Go to **Actions** → select the test workflow (e.g. `Test: setup-git-config`)
2. Click **Run workflow** → choose a branch → **Run workflow**

Or via CLI:

```sh
gh workflow run test-setup-git-config.yml
```
